from nicegui import ui

from frontend.widget_factory import (
    create_groups,
)


class NextflowPipelineGUI:
    """
    NiceGUI interface for Nextflow pipelines with schema support
    """

    def __init__(self):
        self.build_ui()

    def build_ui(self):
        """Build the main user interface"""
        # Set dark mode toggle
        dark_mode = ui.dark_mode()

        # Header
        with ui.header(elevated=True).classes("items-center justify-between"):
            ui.label("🧬 DeepLEAP Pipeline UI").classes("text-h5")
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

                # Create all the parameter groups
                create_groups()

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
                            on_click=lambda x: print("yoink"),
                            icon="refresh",
                        ).props("outline")

                    ui.button(
                        "Run Pipeline",
                        on_click=lambda x: print("yoink"),
                        icon="play_arrow",
                    ).props("color=primary size=lg")

            # Output/logs section
            with ui.card().classes("w-full max-w-4xl"):
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


# Main execution
if __name__ in {"__main__", "__mp_main__"}:
    app = NextflowPipelineGUI()
    ui.run(title="DeepLEAP Pipeline Interface", port=8000, reload=True, show=True)
