import os
import subprocess
from asyncio.subprocess import STDOUT
from cmath import log
from pathlib import Path

from loguru import logger
from nicegui import app, ui
from typer import Typer
from typing_extensions import Optional

from frontend import components, config, db
from frontend.page_create_run import CreateDeepLEAPRunGUI
from frontend.page_pipeline_run_info import view_run_info
from frontend.page_view_runs import view_runs

typ_app = Typer()


@ui.page("/")
def index():
    components.navbar()
    with ui.column().classes("w-full items-center p-4 gap-4"):
        with ui.card().classes("w-full max-w-4xl"):
            ui.label("index")
            ui.button("Launch test pipeline", on_click=launch_test_pipeline)


def launch_test_pipeline():
    logger.info("Launching test pipeline...")
    subprocess.run(
        "docker run -v frontend_deep-leap-data:/data dlejeune/deepleap nextflow run hello",
        shell=True,
    )


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


def init():
    print(components.WELCOME_BANNER)
    logger.info("Initializing DeepLEAP Pipeline UI...")
    config_values = config.get_config()

    logger.info(f"Using database URL: {config_values['db_url']}")
    db.create_if_not_exists(config_values["db_url"])

    dirs_to_create = ["nextflow_work_dir", "nextflow_cache_dir", "data_dir"]

    for dir in dirs_to_create:
        logger.info(f"Ensuring {dir} exists at {config_values[dir]}...")
        if not Path(config_values[dir]).exists():
            Path(config_values[dir]).mkdir(parents=True, exist_ok=True)


@typ_app.command("run")
def run():
    config_file = os.getenv("DEEPLEAP_CONFIG_FILE")
    if config_file:
        config.set_config_file(Path(config_file))

    port = config.get_config().get("port", 8080)

    init()
    app.on_startup(init)
    ui.run(index, title="DeepLEAP Pipeline", port=port, reload=True, show=True)


if __name__ in {"__main__", "__mp_main__"}:
    run()
