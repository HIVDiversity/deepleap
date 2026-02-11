import json
import subprocess
from pathlib import Path
from typing import Any, Dict

from nicegui import ui

from frontend.objects import PipelineParams
from frontend.params import build_params
from frontend.widget_factory import create_parameter_widget


class NextflowPipelineGUI:
    """
    NiceGUI interface for Nextflow pipelines with schema support
    """

    def __init__(self, params: PipelineParams):
        self.grouped_params = {}
        for param in params.parameters:
            if param.group.name not in self.grouped_params:
                self.grouped_params[param.group.name] = []
            self.grouped_params[param.group.name].append(param)
        # self.groups = params.groups
        # self.params = params.parameters

        self.build_ui()
        pass

    def build_ui(self):
        """Build the main user interface"""
        # Set dark mode toggle
        dark_mode = ui.dark_mode()

        # Header
        with ui.header(elevated=True).classes("items-center justify-between"):
            ui.label("🧬 Nextflow Pipeline").classes("text-h5")
            ui.button(icon="dark_mode", on_click=dark_mode.toggle).props("flat round")

        # Main content container
        with ui.column().classes("w-full items-center p-4 gap-4"):
            # Parameter configuration card
            with ui.card().classes("w-full max-w-6xl"):
                with ui.card_section():
                    ui.label("Pipeline Configuration").classes("text-h6")
                    ui.separator()

                # Search/filter for parameters (useful with 20+ params)
                self.search_input = (
                    ui.input(
                        label="Search parameters",
                        placeholder="Filter parameters by name...",
                    )
                    .classes("w-full mb-4")
                    .on("update:model-value", lambda x: print("womp"))
                )

                with ui.splitter(value=30).classes("w-full h-full") as splitter:
                    with splitter.before:
                        # Tabs for parameter groups
                        with (
                            ui.tabs().props("vertical").classes("w-full h-full") as tabs
                        ):
                            for group in self.grouped_params.keys():
                                ui.tab(group)
                    with splitter.after:
                        with (
                            ui.tab_panels(
                                tabs, value=list(self.grouped_params.keys())[0]
                            )
                            .props("vertical")
                            .classes("w-full h-full")
                        ):
                            for group in self.grouped_params:
                                with ui.tab_panel(group):
                                    params = self.grouped_params.get(group, [])
                                    with ui.card().classes("w-full h-full"):
                                        with ui.column().classes("w-full"):
                                            for param in params:
                                                widget = create_parameter_widget(param)

                    # # Tab panels with parameters
                    # with ui.tab_panels(tabs, value=self.groups[0].name).classes(
                    #     "w-full"
                    # ):
                    #     for param in self.params:
                    #         with ui.tab_panel(param.group.name):

                    #             # Use expansion panels for better organization with many params
                    #             with ui.column().classes("w-full gap-2"):
                    #                 for param in params:
                    #                     if param.get("hidden"):
                    #                         continue

                    #                     # Create container for each parameter
                    #                     with (
                    #                         ui.card()
                    #                         .classes("w-full")
                    #                         .style("container-param-" + param["name"])
                    #                     ):
                    #                         with ui.row().classes(
                    #                             "w-full items-start gap-4"
                    #                         ):
                    #                             # Parameter widget (takes most space)
                    #                             with ui.column().classes("flex-grow"):
                    #                                 widget = (
                    #                                     self.create_parameter_widget(
                    #                                         param
                    #                                     )
                    #                                 )
                    #                                 self.param_widgets[
                    #                                     param["name"]
                    #                                 ] = widget

                    #                                 # Help text
                    #                                 if param.get("help"):
                    #                                     ui.label(param["help"]).classes(
                    #                                         "text-xs opacity-70"
                    #                                     )

            # Control panel
            with ui.card().classes("w-full max-w-6xl"):
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
                            on_click=lambda x: print("yoink"),
                            icon="refresh",
                        ).props("outline")

                    ui.button(
                        "Run Pipeline",
                        on_click=lambda x: print("yoink"),
                        icon="play_arrow",
                    ).props("color=primary size=lg")

            # Output/logs section
            with ui.card().classes("w-full max-w-6xl"):
                with ui.card_section():
                    ui.label("Pipeline Output").classes("text-h6")
                    ui.separator()

                self.log_area = ui.log().classes("w-full h-80")

                with ui.row().classes("w-full justify-end mt-2"):
                    ui.button(
                        "Clear Log",
                        on_click=lambda: self.log_area.clear(),
                        icon="clear",
                    ).props("flat")

    # def filter_parameters(self, e):
    #     """Filter visible parameters based on search"""
    #     search_term = e.args.lower() if e.args else ""

    #     for param_name in self.param_widgets.keys():
    #         container = ui.context.client.elements.get(f"container-param-{param_name}")
    #         # This is a simplified version - in practice you'd need to handle visibility differently
    #         # For now, just log the search
    #         if search_term:
    #             self.log_area.push(f"Searching for: {search_term}")

    # def get_current_params(self) -> Dict[str, Any]:
    #     """Get current parameter values"""
    #     params = {}
    #     for name, widget in self.param_widgets.items():
    #         value = widget.value
    #         # Don't include empty strings or None values
    #         if value is not None and value != "":
    #             params[name] = value
    #     return params

    # def export_config(self):
    #     """Export configuration to JSON file"""
    #     params = self.get_current_params()
    #     config_path = Path("pipeline_config.json")

    #     with open(config_path, "w") as f:
    #         json.dump(params, f, indent=2)

    #     ui.notify(f"✓ Configuration saved to {config_path}", type="positive")
    #     self.log_area.push(f"[CONFIG] Exported to {config_path}")

    # def load_config(self):
    #     """Load configuration from JSON file"""
    #     config_path = Path("pipeline_config.json")

    #     if not config_path.exists():
    #         ui.notify("No configuration file found", type="warning")
    #         return

    #     with open(config_path, "r") as f:
    #         params = json.load(f)

    #     for name, value in params.items():
    #         if name in self.param_widgets:
    #             self.param_widgets[name].value = value

    #     ui.notify("✓ Configuration loaded", type="positive")
    #     self.log_area.push(f"[CONFIG] Loaded from {config_path}")

    # def reset_defaults(self):
    #     """Reset all parameters to defaults"""
    #     for section_params in self.parameters.values():
    #         for param in section_params:
    #             if param["name"] in self.param_widgets:
    #                 self.param_widgets[param["name"]].value = param.get("default", "")

    #     ui.notify("✓ Reset to defaults", type="info")
    #     self.log_area.push("[CONFIG] Reset all parameters to defaults")

    # def run_pipeline(self):
    #     """Execute the Nextflow pipeline"""
    #     params = self.get_current_params()

    #     # Build Nextflow command
    #     cmd = ["nextflow", "run", self.pipeline_path]

    #     for name, value in params.items():
    #         if isinstance(value, bool):
    #             if value:
    #                 cmd.append(f"--{name}")
    #         else:
    #             cmd.extend([f"--{name}", str(value)])

    #     cmd_str = " ".join(cmd)
    #     self.log_area.push(f"[RUN] Command: {cmd_str}")
    #     ui.notify("Pipeline starting...", type="info")

    # # In production, you'd run this asynchronously
    # try:
    #     # Uncomment to actually execute:
    #     # process = subprocess.Popen(
    #     #     cmd,
    #     #     stdout=subprocess.PIPE,
    #     #     stderr=subprocess.PIPE,
    #     #     text=True
    #     # )
    #     #
    #     # # Stream output
    #     # for line in process.stdout:
    #     #     self.log_area.push(line.rstrip())
    #     #
    #     # process.wait()
    #     #
    #     # if process.returncode == 0:
    #     #     ui.notify('✓ Pipeline completed successfully', type='positive')
    #     # else:
    #     #     ui.notify('✗ Pipeline failed', type='negative')

    #     self.log_area.push("[INFO] Pipeline would execute here")
    #     self.log_area.push("[INFO] Uncomment subprocess code to run for real")

    # except Exception as e:
    #     self.log_area.push(f"[ERROR] {str(e)}")
    #     ui.notify(f"Error: {str(e)}", type="negative")


# Main execution
if __name__ in {"__main__", "__mp_main__"}:
    # Initialize with your schema path
    # app = NextflowPipelineGUI(schema_path='nextflow_schema.json', pipeline_path='main.nf')
    app = NextflowPipelineGUI(build_params())  # Uses defaults

    ui.run(title="Nextflow Pipeline Interface", port=8080, reload=True, show=True)
