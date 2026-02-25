from nicegui import ui
from sqlmodel import Session, select

from frontend.db import get_engine
from frontend.models import PipelineRun


def view_runs():
    ui.label("Pipeline Runs").classes("text-2xl font-bold")

    with Session(get_engine()) as session:
        pipeline_runs = session.exec(select(PipelineRun)).all()

    rows = []
    for run in pipeline_runs:
        rows.append(
            {
                "name": run.name,
                "status": run.status or "unknown",
                "started_at": run.started_at.strftime("%Y-%m-%d %H:%M")
                if run.started_at
                else "N/A",
                "finished_at": run.finished_at.strftime("%Y-%m-%d %H:%M")
                if run.finished_at
                else "N/A",
                "id": run.id,
            }
        )

    table = ui.table(rows=rows).classes("w-full")
    with table.add_slot("body-cell-status"):
        with table.cell("status"):
            ui.badge().props("""
                :color="props.value === 'success' ? 'green' : props.value === 'failed' ? 'red' : props.value === 'pending' ? 'orange' : 'gray'"
                :label="props.value"
                """)

    table.on("rowClick", lambda e: ui.navigate.to(f"/run/{e.args[1]['id']}"))
