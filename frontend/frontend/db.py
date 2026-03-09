from pathlib import Path

from loguru import logger
from sqlmodel import Session, SQLModel, create_engine
from typer import Typer

from frontend import config, models

app = Typer()


def get_engine(db_url="sqlite:///deepleap_runs.db"):
    config_values = config.get_config()
    if config_values.get("db_url"):
        db_url = config_values["db_url"]

    return create_engine(db_url, echo=False)


def create_if_not_exists(db_url: str):
    filename = Path(db_url.replace("sqlite:///", ""))
    logger.info(f"Checking if database file {filename} exists...")
    if not filename.exists():
        logger.info(f"Database file {filename} does not exist. Creating database...")
        init_db()
    else:
        logger.info(
            f"Database file {filename} already exists. Skipping database creation."
        )


@app.command()
def init_db():
    engine = get_engine()
    SQLModel.metadata.create_all(engine)


@app.command()
def reset_db():
    engine = get_engine()
    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)


if __name__ == "__main__":
    app()
