from nicegui import ui
import subprocess
import json
from pathlib import Path
from typing import Dict, Any


class NextflowPipelineGUI:
    """
    NiceGUI interface for Nextflow pipelines with schema support
    """

    def __init__(self, schema_path: str = None, pipeline_path: str = "main.nf"):
        self.schema_path = schema_path
        self.pipeline_path = pipeline_path
        self.param_values = {}
        self.param_widgets = {}
        self.parameters = {}

        # Load parameters from schema if provided
        if schema_path and Path(schema_path).exists():
            self.parameters = self.load_schema(schema_path)
        else:
            # Use default parameters if no schema
            self.parameters = self.get_default_parameters()

    def load_schema(self, schema_path: str) -> Dict[str, Any]:
        """Load and parse Nextflow schema JSON"""
        with open(schema_path, "r") as f:
            schema = json.load(f)

        parameters = {}
        definitions = schema.get("definitions", {})

        for group_name, group_data in definitions.items():
            display_name = group_data.get("title", group_name.replace("_", " ").title())
            params = []
            properties = group_data.get("properties", {})

            for param_name, param_data in properties.items():
                param_config = {
                    "name": param_name,
                    "label": param_data.get(
                        "description", param_name.replace("_", " ").title()
                    ),
                    "help": param_data.get("help_text", ""),
                    "default": param_data.get("default", ""),
                    "hidden": param_data.get("hidden", False),
                }

                # Determine parameter type
                param_type = param_data.get("type", "string")

                if "enum" in param_data:
                    param_config["type"] = "select"
                    param_config["options"] = param_data["enum"]
                elif param_type in ["integer", "number"]:
                    param_config["type"] = "number"
                    param_config["min"] = param_data.get("minimum")
                    param_config["max"] = param_data.get("maximum")
                elif param_type == "boolean":
                    param_config["type"] = "checkbox"
                else:
                    param_config["type"] = "text"

                param_config["format"] = param_data.get("format", "")
                params.append(param_config)

            if params:
                parameters[display_name] = params

        return parameters

    def get_default_parameters(self) -> Dict[str, Any]:
        """Default parameters if no schema is provided"""
        return {
            "Input/Output": [
                {
                    "name": "input",
                    "type": "text",
                    "label": "Input file/directory",
                    "default": "",
                    "help": "Path to input data",
                },
                {
                    "name": "outdir",
                    "type": "text",
                    "label": "Output directory",
                    "default": "./results",
                    "help": "Where to save results",
                },
            ],
            "General Options": [
                {
                    "name": "help",
                    "type": "checkbox",
                    "label": "Show help",
                    "default": False,
                },
            ],
        }

    def create_parameter_widget(self, param: Dict[str, Any]):
        """Create appropriate widget for parameter type"""
        param_type = param["type"]

        if param_type == "text":
            widget = ui.input(
                label=param["label"],
                value=str(param.get("default", "")),
                placeholder=param.get("help", ""),
            ).classes("w-full")

            # Add file picker button for file/directory paths
            if param.get("format") in ["file-path", "directory-path"]:
                with ui.row().classes("w-full items-center gap-2"):
                    widget.classes("flex-grow")
                    ui.button(
                        icon="folder_open",
                        on_click=lambda: ui.notify("File picker would open here"),
                    ).props("flat dense")

        elif param_type == "select":
            widget = ui.select(
                label=param["label"],
                options=param["options"],
                value=param.get(
                    "default", param["options"][0] if param["options"] else None
                ),
            ).classes("w-full")

        elif param_type == "number":
            widget = ui.number(
                label=param["label"],
                value=param.get("default", 0),
                min=param.get("min"),
                max=param.get("max"),
            ).classes("w-full")

        elif param_type == "checkbox":
            widget = ui.checkbox(text=param["label"], value=param.get("default", False))

        else:
            widget = ui.input(
                label=param["label"], value=str(param.get("default", ""))
            ).classes("w-full")

        return widget

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
                    .on("update:model-value", self.filter_parameters)
                )

                # Tabs for parameter groups
                with ui.tabs().classes("w-full") as tabs:
                    tab_list = list(self.parameters.keys())
                    for section_name in tab_list:
                        ui.tab(section_name)

                # Tab panels with parameters
                with ui.tab_panels(
                    tabs, value=tab_list[0] if tab_list else None
                ).classes("w-full"):
                    for section_name, params in self.parameters.items():
                        with ui.tab_panel(section_name):
                            # Use expansion panels for better organization with many params
                            with ui.column().classes("w-full gap-2"):
                                for param in params:
                                    if param.get("hidden"):
                                        continue

                                    # Create container for each parameter
                                    with (
                                        ui.card()
                                        .classes("w-full")
                                        .style("container-param-" + param["name"])
                                    ):
                                        with ui.row().classes(
                                            "w-full items-start gap-4"
                                        ):
                                            # Parameter widget (takes most space)
                                            with ui.column().classes("flex-grow"):
                                                widget = self.create_parameter_widget(
                                                    param
                                                )
                                                self.param_widgets[param["name"]] = (
                                                    widget
                                                )

                                                # Help text
                                                if param.get("help"):
                                                    ui.label(param["help"]).classes(
                                                        "text-xs opacity-70"
                                                    )

            # Control panel
            with ui.card().classes("w-full max-w-6xl"):
                with ui.row().classes("w-full justify-between items-center"):
                    with ui.row().classes("gap-2"):
                        ui.button(
                            "Load Config", on_click=self.load_config, icon="upload"
                        ).props("outline")
                        ui.button(
                            "Export Config",
                            on_click=self.export_config,
                            icon="download",
                        ).props("outline")
                        ui.button(
                            "Reset to Defaults",
                            on_click=self.reset_defaults,
                            icon="refresh",
                        ).props("outline")

                    ui.button(
                        "Run Pipeline", on_click=self.run_pipeline, icon="play_arrow"
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

    def filter_parameters(self, e):
        """Filter visible parameters based on search"""
        search_term = e.args.lower() if e.args else ""

        for param_name in self.param_widgets.keys():
            container = ui.context.client.elements.get(f"container-param-{param_name}")
            # This is a simplified version - in practice you'd need to handle visibility differently
            # For now, just log the search
            if search_term:
                self.log_area.push(f"Searching for: {search_term}")

    def get_current_params(self) -> Dict[str, Any]:
        """Get current parameter values"""
        params = {}
        for name, widget in self.param_widgets.items():
            value = widget.value
            # Don't include empty strings or None values
            if value is not None and value != "":
                params[name] = value
        return params

    def export_config(self):
        """Export configuration to JSON file"""
        params = self.get_current_params()
        config_path = Path("pipeline_config.json")

        with open(config_path, "w") as f:
            json.dump(params, f, indent=2)

        ui.notify(f"✓ Configuration saved to {config_path}", type="positive")
        self.log_area.push(f"[CONFIG] Exported to {config_path}")

    def load_config(self):
        """Load configuration from JSON file"""
        config_path = Path("pipeline_config.json")

        if not config_path.exists():
            ui.notify("No configuration file found", type="warning")
            return

        with open(config_path, "r") as f:
            params = json.load(f)

        for name, value in params.items():
            if name in self.param_widgets:
                self.param_widgets[name].value = value

        ui.notify("✓ Configuration loaded", type="positive")
        self.log_area.push(f"[CONFIG] Loaded from {config_path}")

    def reset_defaults(self):
        """Reset all parameters to defaults"""
        for section_params in self.parameters.values():
            for param in section_params:
                if param["name"] in self.param_widgets:
                    self.param_widgets[param["name"]].value = param.get("default", "")

        ui.notify("✓ Reset to defaults", type="info")
        self.log_area.push("[CONFIG] Reset all parameters to defaults")

    def run_pipeline(self):
        """Execute the Nextflow pipeline"""
        params = self.get_current_params()

        # Build Nextflow command
        cmd = ["nextflow", "run", self.pipeline_path]

        for name, value in params.items():
            if isinstance(value, bool):
                if value:
                    cmd.append(f"--{name}")
            else:
                cmd.extend([f"--{name}", str(value)])

        cmd_str = " ".join(cmd)
        self.log_area.push(f"[RUN] Command: {cmd_str}")
        ui.notify("Pipeline starting...", type="info")

        # In production, you'd run this asynchronously
        try:
            # Uncomment to actually execute:
            # process = subprocess.Popen(
            #     cmd,
            #     stdout=subprocess.PIPE,
            #     stderr=subprocess.PIPE,
            #     text=True
            # )
            #
            # # Stream output
            # for line in process.stdout:
            #     self.log_area.push(line.rstrip())
            #
            # process.wait()
            #
            # if process.returncode == 0:
            #     ui.notify('✓ Pipeline completed successfully', type='positive')
            # else:
            #     ui.notify('✗ Pipeline failed', type='negative')

            self.log_area.push("[INFO] Pipeline would execute here")
            self.log_area.push("[INFO] Uncomment subprocess code to run for real")

        except Exception as e:
            self.log_area.push(f"[ERROR] {str(e)}")
            ui.notify(f"Error: {str(e)}", type="negative")


# Main execution
if __name__ in {"__main__", "__mp_main__"}:
    # Initialize with your schema path
    # app = NextflowPipelineGUI(schema_path='nextflow_schema.json', pipeline_path='main.nf')
    app = NextflowPipelineGUI()  # Uses defaults
    app.build_ui()

    ui.run(title="Nextflow Pipeline Interface", port=8080, reload=True, show=True)
