from sqlmodel import Session, SQLModel, create_engine
from typer import Typer

from frontend import models

app = Typer()


def get_engine(db_url="sqlite:///deepleap_runs.db"):
    return create_engine(db_url, echo=True)


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
