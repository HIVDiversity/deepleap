import asyncio
import tomllib
import uuid
from pathlib import Path

from nicegui import app, ui

from frontend.runner import create_pipeline_run
from frontend.widget_factory import (
    create_groups,
)


class CreateDeepLEAPRunGUI:
    """
    NiceGUI interface for Nextflow pipelines with schema support
    """

    def __init__(self, data_root):

        self.data_root = data_root

        self.build_ui()

    def build_ui(self):
        """Build the main user interface"""

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
                create_groups(form_values, (self.data_root / "temp_uploads"))

            # Control panel
            with ui.card().classes("w-full max-w-4xl"):
                with ui.row().classes("w-full justify-between items-center"):
                    # with ui.row().classes("gap-2"):
                    # ui.button(
                    #     "Load Config",
                    #     on_click=lambda x: print("yoink"),
                    #     icon="upload",
                    # ).props("outline")
                    # ui.button(
                    #     "Export Config",
                    #     on_click=lambda x: print("yoink"),
                    #     icon="download",
                    # ).props("outline")

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

        run_id = str(uuid.uuid4())
        pipeline_run_root = self.data_root / run_id
        pipeline_run_root.mkdir()
        (pipeline_run_root / "seqs").mkdir()
        (pipeline_run_root / "outputs").mkdir()

        new_samplesheet_path = pipeline_run_root / "samplesheet.csv"
        new_ref_seq_path = pipeline_run_root / Path(form_values["ref_seq"]).name
        new_seq_paths = []

        Path(form_values["samplesheet"]).rename(new_samplesheet_path)
        Path(form_values["ref_seq"]).rename(new_ref_seq_path)
        for file in form_values["seqs"]:
            new_filename = pipeline_run_root / "seqs" / Path(file).name
            Path(file).rename(new_filename)
            new_seq_paths.append(new_filename)

        roi = form_values.get("region_name")
        params = {
            "run_name": form_values["run_name"],
            "samplesheet": new_samplesheet_path,
            "sample_base_dir": pipeline_run_root / "seqs",
            "output_dir": pipeline_run_root / "outputs",
            "ref_file": new_ref_seq_path,
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
        asyncio.gather(
            create_pipeline_run(params, optional_params, run_id, pipeline_run_root)
        )
        ui.notify(f"Successfully submitted pipeline job with ID {run_id}")
        ui.navigate.to(f"/run/{run_id}")
