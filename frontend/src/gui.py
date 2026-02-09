from nicegui import ui
import subprocess
import json
from pathlib import Path
from typing import Dict, Any
import tomllib


class DeepLeapGUI:
    """
    NiceGUI interface for the DeepLEAP pipeline
    """

    def __init__(self, param_schema: Path):
        self.schema = param_schema

        self.param_values = {}
        self.param_widgets = {}
        self.parameters = {}
