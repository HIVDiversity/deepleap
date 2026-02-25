import csv
import json
import tarfile
from pathlib import Path

from nicegui import ui
from sqlmodel import Session, select

from frontend.db import get_engine
from frontend.models import PipelineRun


def view_run_info(run_id):
    with Session(get_engine()) as session:
        pipeline_run = session.exec(
            select(PipelineRun).where(PipelineRun.id == run_id)
        ).first()

    if not pipeline_run:
        ui.label("Pipeline run not found.")
    else:
        pipeline_run_info = _load_run_info(
            Path(pipeline_run.root_foler)
            / "outputs/execution_report/output_dir/data/data.json"
        )
        card = ui.card().classes("w-full")
        with card:
            with ui.row().classes("justify-between w-full items-center"):
                ui.label(f"Pipeline run: {pipeline_run.name}").classes(
                    "text-lg font-medium"
                )

                _get_status_badge(pipeline_run.status or "unknown")
            ui.separator()

            with ui.row().classes("justify-between gap-6 w-full"):
                ui.label(f"Run ID: {run_id}").classes("text-sm text-gray-600")
                if pipeline_run.started_at:
                    ui.label(
                        f"Started: {pipeline_run.started_at.isoformat(timespec='minutes')}"
                    ).classes("text-sm text-gray-600")
                if pipeline_run.finished_at:
                    ui.label(
                        f"Finished: {pipeline_run.finished_at.isoformat(timespec='minutes')}"
                    ).classes("text-sm text-gray-600")

            if pipeline_run.status == "success":
                with ui.row():
                    run_results_overview(pipeline_run_info)

                # ui.item(
                #     "Samplesheet", icon="table_view", on_click=samplesheet_dialog.open
                # ).props("rounded color=purple")

            _sample_file_expand(pipeline_run)

            _log_expand(pipeline_run)

            with ui.row().classes("justify-end w-full"):
                _actions(pipeline_run)


def run_results_overview(run_info):
    with ui.column():
        table_columns = [
            {"name": "parameter", "label": "param", "field": "parameter"},
            {"name": "value", "label": "value", "field": "value"},
        ]
        table_rows = [
            {
                "parameter": "Pipeline Version",
                "value": run_info.get("pipeline_version", "N/A"),
            },
            {
                "parameter": "Aligner",
                "value": run_info["nf_param_dump"].get("aligner", "N/A"),
            },
            {
                "parameter": "Trimming Method",
                "value": run_info["nf_param_dump"].get("trim_method", "N/A"),
            },
            {
                "parameter": "Initial Sequence Count",
                "value": run_info.get("seq_count_pre", "N/A"),
            },
            {
                "parameter": "Final Sequence Count",
                "value": run_info.get("seq_count_post", "N/A"),
            },
            {
                "parameter": "Percentage Lost",
                "value": str(run_info.get("pct_seqs_lost", "N/A")) + "%",
            },
        ]
        table = ui.table(columns=table_columns, rows=table_rows, row_key="id").props(
            "grid"
        )

        with table.add_slot("item"):
            with (
                ui.card()
                .tight()
                .props("flat bordered")
                .classes("m-1 items-stretch text-center")
            ):
                with ui.card_section():
                    ui.label().props(":innerHTML=props.row.parameter").classes(
                        "font-bold"
                    )
                ui.separator()
                with ui.card_section():
                    ui.label().props(""" :innerHTML="props.row.value"
                        """)

    pass


def _build_functional_filter_report_modal(upset_plot_dir: Path):
    upset_plot = upset_plot_dir.glob("*UpSetPlot.svg").__next__()
    if not upset_plot.exists():
        ui.notify("Functional filter report not found.", color="red")
        return

    with (
        ui.dialog() as report_dialog,
        ui.card().style("max-width: 100%;"),
    ):
        # reader = csv.DictReader(report_file.open())
        # rows = []
        # field_names = reader.fieldnames
        # for row in reader:
        #     rows.append(row)

        # table = ui.table(
        #     rows=rows,
        # ).classes("w-screen")
        with ui.row().classes("justify-between w-full"):
            ui.label("Functional Filter Report").classes("text-lg font-medium")
            ui.button(
                "",
                icon="help",
                on_click=lambda: ui.navigate.to("https://upset.app/", new_tab=True),
            )
        ui.separator()
        ui.html(upset_plot.read_text(), sanitize=False).classes("w-full")

    return report_dialog


def _load_run_info(run_root: Path):
    with run_root.open("r") as f:
        info = json.load(f)

    return info


def _update_log_area(log_filehandle, log_area):
    with log_filehandle as f:
        log_area.value = f.read()


def _watch_status(run_id):
    with Session(get_engine()) as session:
        pipeline_run = session.exec(
            select(PipelineRun).where(PipelineRun.id == run_id)
        ).first()
        if pipeline_run:
            if pipeline_run.status in ("failed", "success"):
                ui.navigate.reload()
    return None


def _get_status_badge(status_text):
    # small "tab"-like status indicator
    st_lower = status_text.lower()
    if st_lower in ("success", "completed", "done"):
        status_classes = "bg-green-100 text-green-800"
    elif st_lower in ("running", "in_progress", "started", "pending"):
        status_classes = "bg-yellow-100 text-yellow-800"
    elif st_lower in ("failed", "error"):
        status_classes = "bg-red-100 text-red-800"
    else:
        status_classes = "bg-gray-100 text-gray-800"

    ui.label(f"Status: {status_text}").classes(
        f"px-3 py-1 rounded-full text-sm {status_classes}"
    )


def _build_samplesheet_dialog(pipeline_run):
    with (
        ui.dialog() as samplesheet_dialog,
        ui.card().classes("size-fit"),
    ):
        samplesheet_file = Path(pipeline_run.root_foler) / "samplesheet.csv"
        with ui.row().classes("justify-between w-full"):
            ui.label("Samplesheet").classes("text-lg font-medium")
            ui.button(
                "Download",
                on_click=lambda: ui.download(samplesheet_file),
                icon="download",
            ).props("flat text-color=primary")
            ui.button("", on_click=samplesheet_dialog.close, icon="close").props(
                "flat text-color=primary"
            )

        with ui.row().classes("justify-start gap-4 w-full"):
            reader = csv.DictReader(samplesheet_file.open())
            rows = []
            field_names = reader.fieldnames
            for row in reader:
                rows.append(row)

            columns = [
                {
                    "name": "sample_id",
                    "label": "Sample ID",
                    "field": "sample_id",
                },
                {
                    "name": "cap_name",
                    "label": "Participant ID",
                    "field": "cap_name",
                },
                {
                    "name": "visit_id",
                    "label": "Visit Code",
                    "field": "visit_id",
                },
                {
                    "name": "filename",
                    "label": "Filename",
                    "field": "filename",
                },
            ]

            ui.table(columns=columns, rows=rows, pagination=4).classes("w-full")
    return samplesheet_dialog


def _build_ref_dialog(pipeline_run):
    with ui.dialog() as ref_dialog, ui.card().classes("w-lg"):
        ref_file = Path(pipeline_run.root_foler) / pipeline_run.ref_file
        with ui.row().classes("justify-between w-full"):
            ui.label("Reference Sequence").classes("text-lg font-medium")
            ui.button(
                "Download",
                on_click=lambda: ui.download(ref_file),
                icon="download",
            ).props("flat text-color=primary")
            ui.button("", on_click=ref_dialog.close, icon="close").props(
                "flat text-color=primary"
            )

        text = ref_file.read_text()
        ref_area = (
            ui.textarea(value=text).classes("font-mono w-full h-full").props("readonly")
        )

    return ref_dialog


def _sample_file_expand(pipeline_run):
    with ui.expansion("Input Files", icon="article", value=False).classes(
        "w-full text-base border border-gray-400 rounded-md mb-3"
    ):
        with ui.list().props("separator"):
            for seq in Path(pipeline_run.root_foler).glob("seqs/*"):
                with ui.item():
                    with ui.item_section():
                        ui.item(seq.name).classes("font-mono")
                    with ui.item_section().props("side"):
                        ui.button(icon="download").props("flat").on(
                            "click", lambda e, s=seq: ui.download(s)
                        )


def _log_expand(pipeline_run):
    with ui.expansion("Execution Log", icon="sticky_note_2", value=False).classes(
        "w-full text-base border border-gray-400 rounded-md mb-3"
    ):
        log_area = (
            ui.textarea("").classes("w-full font-mono").props("autogrow readonly")
        )
        log_file = Path(pipeline_run.root_foler) / "pipeline.log"
        if pipeline_run.status in (
            "running",
            "in_progress",
            "started",
            "pending",
        ):
            ui.timer(1.0, lambda: _update_log_area(log_file.open("r"), log_area))
            ui.timer(5.0, lambda: _watch_status(pipeline_run.id))
        else:
            log_area.value = log_file.read_text()


def _download_results(pipeline_run, temp_dir=Path("temp/")):
    results_folder = Path(pipeline_run.root_foler)
    temp_dir.mkdir(exist_ok=True)
    tar_path = temp_dir / f"{pipeline_run.name}_results.tar.gz"
    with tarfile.open(tar_path, "w:gz") as tar:
        tar.add(results_folder, arcname=results_folder.name)
    ui.download(tar_path)
    # tar_path.unlink()  # clean up the temporary tar file


def view_run_report(pipeline_run):
    report_file_dir = (
        Path(pipeline_run.root_foler) / "outputs/execution_report/output_dir/"
    )
    report_file = next(report_file_dir.glob("*.pdf"), None)

    if report_file:
        ui.button(
            "Download Report",
            icon="picture_as_pdf",
            on_click=lambda: ui.download(report_file),
        ).props("rounded")


def _actions(pipeline_run):
    samplesheet_dialog = _build_samplesheet_dialog(pipeline_run)
    ref_dialog = _build_ref_dialog(pipeline_run)
    report_dialog = _build_functional_filter_report_modal(
        Path(pipeline_run.root_foler) / "outputs/execution_report/output_dir/data"
    )

    with (
        ui.dropdown_button("Actions", icon="flash_on")
        .props("flat size=md")
        .classes("bg-blue-500 text-white hover:bg-blue-600")
    ):
        with ui.item(on_click=samplesheet_dialog.open):
            with ui.item_section().props("avatar"):
                ui.icon("table_view")
            with ui.item_section():
                ui.label("View Samplesheet").classes("")
            # with ui.item_section():
        with ui.item(on_click=ref_dialog.open):
            with ui.item_section().props("avatar"):
                ui.icon("book")
            with ui.item_section():
                ui.label("View Reference Sequence").classes("")

        if pipeline_run.status == "success":
            with ui.item(
                on_click=lambda: _download_results(pipeline_run),
            ):
                with ui.item_section().props("avatar"):
                    ui.icon("download")
                with ui.item_section():
                    ui.label("Download Results").classes("")
            if report_dialog:
                with ui.item("", on_click=report_dialog.open):
                    with ui.item_section().props("avatar"):
                        ui.icon("filter_alt")
                    with ui.item_section():
                        ui.label("Show Functional Filter UpSetPlot")

                report_file_dir = (
                    Path(pipeline_run.root_foler)
                    / "outputs/execution_report/output_dir/"
                )
                report_file = next(report_file_dir.glob("*.pdf"), None)
                if report_file:
                    with ui.item(on_click=lambda: ui.download(report_file)):
                        with ui.item_section().props("avatar"):
                            ui.icon("picture_as_pdf")
                        with ui.item_section():
                            ui.label("Download Full Report").classes("")
