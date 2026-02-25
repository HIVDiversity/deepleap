import tomllib
from pathlib import Path

from nicegui import ui

from frontend import components
from frontend.page_create_run import CreateDeepLEAPRunGUI
from frontend.page_pipeline_run_info import view_run_info
from frontend.page_view_runs import view_runs


@ui.page("/")
def index():
    components.navbar()
    with ui.column().classes("w-full items-center p-4 gap-4"):
        with ui.card().classes("w-full max-w-4xl"):
            ui.label("index")


@ui.page("/create")
def create_run():
    components.navbar()
    with open("config.toml", "rb") as f:
        config_values = tomllib.load(f)

    deepleap_app = CreateDeepLEAPRunGUI(Path(config_values["data_dir"]))


@ui.page("/run/{run_id}")
def run_info(run_id):
    components.navbar()
    with ui.column().classes("w-full items-center p-4 gap-4"):
        view_run_info(run_id)


@ui.page("/runs")
def all_runs():
    components.navbar()
    with ui.column().classes("w-full items-center p-4 gap-4"):
        with ui.card().classes("w-full max-w-4xl"):
            view_runs()


if __name__ in {"__main__", "__mp_main__"}:
    ui.run(index, title="DeepLEAP Pipeline", port=8000, reload=True, show=True)
