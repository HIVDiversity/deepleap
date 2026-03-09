from datetime import datetime
from pathlib import Path

from sqlmodel import JSON, Field, SQLModel
from typing_extensions import Optional


class PipelineRun(SQLModel, table=True):
    id: str = Field(default=None, primary_key=True)
    name: str
    status: str
    started_at: datetime
    finished_at: Optional[datetime]
    root_folder: str
    ref_file: str
    config: Optional[str] = None
    run_command: str = ""
