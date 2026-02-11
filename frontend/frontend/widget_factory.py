from nicegui import ui

from .objects import (
    BoolParamType,
    FileParamType,
    IntParamType,
    Parameter,
    ParamType,
    PipelineParams,
    SelectParamType,
    StringParamType,
)


def create_parameter_widget(param: Parameter):
    """
    Creates a NiceGUI widget for a given parameter.

    Args:
        param: The parameter to create a widget for.
    """
    label = f"{param.name}{' *' if param.required else ''}"

    widget = None
    if isinstance(param.param_type, StringParamType):
        widget = ui.input(label=label, value=param.value).classes("w-full")
        if param.param_type.length:
            widget.props(f"maxlength={param.param_type.length}")
    # Regex validation could be added here

    elif isinstance(param.param_type, BoolParamType):
        # The label for a switch is the 'text' parameter
        widget = ui.switch(text=param.name, value=param.value or False).classes(
            "w-full"
        )

    elif isinstance(param.param_type, IntParamType):
        widget = ui.number(label=label, value=param.value, step=1, precision=0).classes(
            "w-full"
        )

        if param.param_type.min_val is not None:
            widget.props(f"min={param.param_type.min_val}")
        if param.param_type.max_val is not None:
            widget.props(f"max={param.param_type.max_val}")

    elif isinstance(param.param_type, SelectParamType):
        widget = ui.select(
            options=param.param_type.items, label=label, value=param.value
        ).classes("w-full")

    elif isinstance(param.param_type, FileParamType):
        widget = ui.upload(label=label, on_upload=lambda x: print("hello")).classes(
            "w-full"
        )

        filetype_info = f"Expected: {param.param_type.filetype}"
        if param.description:
            widget.tooltip(f"{param.description}\n{filetype_info}")
        else:
            widget.tooltip(filetype_info)

    if widget is None:
        widget = ui.label(
            f"Unsupported parameter type: {param.param_type} for {param.name}"
        )

    # Add description as a tooltip if not already handled (e.g., for file type)
    if param.description and not isinstance(param.param_type, FileParamType):
        widget.tooltip(param.description)


def create_pipeline_ui(pipeline_params: PipelineParams):
    """
    Creates a complete NiceGUI UI for all pipeline parameters,
    grouped by their assigned group.

    Args:
        pipeline_params: The pipeline parameters to build the UI for.
    """
    for group in pipeline_params.groups:
        with ui.expansion(group.name, icon=group.icon, value=True).classes("w-full"):
            if group.description:
                ui.label(group.description).classes("text-sm text-gray-600 ml-1")
            for param in pipeline_params.parameters:
                if param.group.name == group.name:
                    create_parameter_widget(param)
