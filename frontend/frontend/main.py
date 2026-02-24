import asyncio
import tomllib
import uuid
from pathlib import Path

from nicegui import app, ui

from frontend.runner import run_pipeline
from frontend.widget_factory import (
    create_groups,
)


class NextflowPipelineGUI:
    """
    NiceGUI interface for Nextflow pipelines with schema support
    """

    def __init__(self, session=None, temp_upload: Path = Path("temp/uploads")):
        with open("config.toml", "rb") as config_file:
            config = tomllib.load(config_file)

        if session:
            self.session = session
        else:
            self.session = "temproot"

        self.upload_root = Path(config["data_dir"]) / self.session

        if not self.upload_root.exists():
            self.upload_root.mkdir(parents=True)
            (self.upload_root / "seqs").mkdir()
            (self.upload_root / "outputs").mkdir()

        self.build_ui()

    def set_session(self, session):
        self.session = "temp"

    def build_ui(self):
        """Build the main user interface"""
        # Set dark mode toggle
        dark_mode = ui.dark_mode()

        # Header
        with ui.header(elevated=True).classes("items-center justify-between"):
            ui.label("🧬 DeepLEAP").classes("text-h5")

            ui.button(icon="dark_mode", on_click=dark_mode.toggle).props("flat round")

        # Main content container
        with ui.column().classes("w-full items-center p-4 gap-4"):
            # Parameter configuration card
            with ui.card().classes("w-full max-w-4xl"):
                with ui.card_section().classes("w-full"):
                    ui.label("Submit a DeepLEAP Run").classes("text-h4")
                    ui.separator()

                with ui.card_section().classes("w-full"):
                    ui.label(
                        "Use the fields below to configure a DeepLAP pipeline run. The defaults are likely sufficient, and so you need only provide a run name and the input files."
                    )
                form_values = {}
                # Create all the parameter groups
                create_groups(form_values, self.upload_root)

            # Control panel
            with ui.card().classes("w-full max-w-4xl"):
                with ui.row().classes("w-full justify-between items-center"):
                    with ui.row().classes("gap-2"):
                        ui.button(
                            "Load Config",
                            on_click=lambda x: print("yoink"),
                            icon="upload",
                        ).props("outline")
                        ui.button(
                            "Export Config",
                            on_click=lambda x: print("yoink"),
                            icon="download",
                        ).props("outline")
                        ui.button(
                            "Reset to Defaults",
                            on_click=lambda x: print(self.session),
                            icon="refresh",
                        ).props("outline")

                    ui.button(
                        "Run Pipeline",
                        on_click=lambda: self.validate_and_run(form_values),
                        icon="play_arrow",
                    ).props("color=primary size=lg")

            # Output/logs section
            with ui.card().classes("w-full max-w-4xl"):
                with ui.card_section():
                    ui.label("Pipeline Output").classes("text-h6")
                    ui.separator()

                self.log_area = ui.log().classes("w-full h-80")

                # ui.timer(1.0, lambda: self.log_area.push(form_values))

                with ui.row().classes("w-full justify-end mt-2"):
                    ui.button(
                        "Clear Log",
                        on_click=lambda: self.log_area.clear(),
                        icon="clear",
                    ).props("flat")

    async def validate_and_run(self, form_values):
        print(form_values)
        required_fields = [
            "run_name",
            "seqs",
            "samplesheet",
            "aligner",
            "preprocess_method",
            "ref_seq",
        ]

        aga_required_args = [
            "region_name_shorthand",
            "region_name",
        ]

        minimap_required_args = ["minimap_roi_start", "minimap_roi_end"]

        if form_values["preprocess_method"] == "AGA":
            required_fields.extend(aga_required_args)
        elif form_values["preprocess_method"] == "MINIMAP2":
            required_fields.extend(minimap_required_args)

        for field in required_fields:
            if field not in form_values:
                ui.notify(f"Missing required field: {field}")
                return
        roi = form_values.get("region_name")
        params = {
            "run_name": form_values["run_name"],
            "samplesheet": form_values["samplesheet"],
            "sample_base_dir": self.upload_root / "seqs",
            "output_dir": self.upload_root / "outputs",
            "ref_file": form_values["ref_seq"],
            "trim_method": form_values["preprocess_method"],
            "region_of_interest": roi if roi else "XXX",
            "aligner": form_values["aligner"],
        }

        optional_params = {
            "aligner_params": form_values.get("aligner_params"),
            "ff_max_stop_pct": form_values.get("ff_max_stop_pct"),
            "ff_include_frameshifts": form_values.get("ff_include_frameshifts"),
            "ff_include_no_stop_codons": form_values.get("ff_include_no_stop_codons"),
            "ff_max_seq_loss": form_values.get("ff_max_seq_loss"),
            "minimap_roi_start": int(form_values.get("minimap_roi_start")),
            "minimap_roi_end": int(form_values.get("minimap_roi_end")),
            "additional_ref": form_values.get("additional_ref"),
            "skip_trim": form_values["skip_trim"],
            "skip_preprocess": form_values["skip_preprocess"],
            "skip_functional_filter": form_values["skip_functional_filter"],
            "region_name_shorthand": form_values.get("region_name_shorthand"),
            "ff_expected_length": form_values.get("ff_expected_length"),
            "add_reference_to_sequences": form_values.get("add_reference_tosequences"),
        }
        self.log_area.push("Launching pipeline.")
        process = await run_pipeline(params, optional_params)
        await asyncio.gather(self.print_log(process.stdout))

    async def print_log(self, stdout):
        while True:
            line = await stdout.readline()
            if not line:
                break
            self.log_area.push(line.decode().rstrip())


# Main execution
if __name__ in {"__main__", "__mp_main__"}:
    deepleap_app = NextflowPipelineGUI()
    app.on_connect(lambda: deepleap_app.set_session(uuid.uuid4().hex))

    ui.run(title="DeepLEAP Pipeline Interface", port=8000, reload=True, show=True)
