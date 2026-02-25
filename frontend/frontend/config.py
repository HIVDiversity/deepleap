import os
import tomllib
from pathlib import Path


def get_config(config_file: Path = Path("config.toml")):
    env_config_file = os.getenv("DEEPLEAP_FRONTEND_CONFIG")
    if env_config_file:
        config_file = Path(env_config_file)

    with open(config_file, "rb") as f:
        config_values = tomllib.load(f)
    return config_values


def set_config_file(config_file: Path):
    os.environ["DEEPLEAP_FRONTEND_CONFIG"] = str(config_file.resolve())
