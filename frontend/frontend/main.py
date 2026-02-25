import tomllib
from pathlib import Path

from nicegui import ui
from typer import Typer
from typing_extensions import Optional

from frontend import components, config, db
from frontend.page_create_run import CreateDeepLEAPRunGUI
from frontend.page_pipeline_run_info import view_run_info
from frontend.page_view_runs import view_runs

app = Typer()


@ui.page("/")
def index():
    components.navbar()
    with ui.column().classes("w-full items-center p-4 gap-4"):
        with ui.card().classes("w-full max-w-4xl"):
            ui.label("index")


@ui.page("/create")
def create_run():
    components.navbar()
    config_values = config.get_config()

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


@app.command("run")
def run(config_file: Optional[Path] = None, port: Optional[int] = 8080):
    if config_file:
        config.set_config_file(config_file)

    config_values = config.get_config()
    db.create_if_not_exists(config_values["db_url"])

    ui.run(index, title="DeepLEAP Pipeline", port=port, reload=True, show=True)


if __name__ in {"__main__", "__mp_main__"}:
    run()
