from .dataclasses import PipelineParams, Group


def build_params() -> PipelineParams:
    # We build the groups and the parameters together. Realistically, it doesn't matter
    # where the various parameters are put, but grouped here for simplicity
    group_main = Group(name="Main", description=None, icon=None)

    group_io = Group(name="Input/Output", description=None, icon=None)
    group_alignment_options = Group(
        name="Alignment Options", description=None, icon=None
    )

    all_params = PipelineParams([], [])

    return all_params
