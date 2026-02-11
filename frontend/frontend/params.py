# NOTE: This file relies on additions to `dataclasses.py`. Before running, please ensure:
# 1. `SelectParamType` is corrected to `items: List[str]`.
# 2. A `FLOAT` member is added to the `ParamType` enum.
# 3. A `FloatParamType` class is defined with `min_val: Optional[float]` and `max_val: Optional[float]`.
# 4. `FloatParamType` is included in the `ParamConfigType` type union.
# 5. `float` is included in the `AnyParamType` type union.

from .objects import (
    BoolParamType,
    FileParamType,
    FloatParamType,
    Group,
    IntParamType,
    Parameter,
    ParamType,
    PipelineParams,
    SelectParamType,
    StringParamType,
)


def build_params() -> PipelineParams:
    """
    Builds the full pipeline parameter structure from the nextflow_schema.json.
    """
    # Define Groups from the schema
    group_input_output = Group(
        name="Input/output options",
        description="Define where the pipeline should find input data and save output data.",
        icon="fas fa-terminal",
    )
    group_operating_modes = Group(
        name="Operating Modes",
        description="Parameters that change the operating mode of the pipeline.",
        icon="fas fa-code-branch",
    )
    group_custom_preprocess = Group(
        name="Custom Preprocess Arguments",
        description="Arguments for the CUSTOM preprocessing mode.",
        icon="fas fa-frog",
    )
    group_aga_preprocess = Group(
        name="AGA Preprocess Arguments",
        description="Arguments for the AGA preprocessing strategy.",
        icon="fas fa-cat",
    )
    group_minimap_trim = Group(
        name="Minimap2 Trim Arguments",
        description="Arguments specifying how minimap2 must trim sequences.",
        icon="fas fa-map-marked-alt",
    )
    group_filtering = Group(
        name="Filtering Options",
        description="Options passed onto the functional filter.",
        icon="fas fa-filter",
    )
    group_misc_process = Group(
        name="Miscellaneous Process Arguments",
        description="Arguments for various third-party tools in the pipeline.",
        icon="fas fa-ellipsis-h",
    )
    group_compute = Group(
        name="Compute Options",
        description="Parameters affecting computational resources.",
        icon="fas fa-desktop",
    )
    group_generic = Group(
        name="Generic options",
        description="Less common options, typically set in a config file.",
        icon="fas fa-file-import",
    )
    group_other = Group(
        name="Other Parameters",
        description="Parameters not otherwise grouped.",
        icon=None,
    )

    groups = [
        group_input_output,
        group_operating_modes,
        group_custom_preprocess,
        group_aga_preprocess,
        group_minimap_trim,
        group_filtering,
        group_misc_process,
        group_compute,
        group_generic,
        group_other,
    ]

    # Define Parameters
    params = [
        # Input/output options
        Parameter(
            name="Samplesheet",
            description="The CSV file that specifies the various samples and metadata to feed into the pipeline.",
            icon="fas fa-file-csv",
            value=None,
            required=True,
            param_type=FileParamType(filetype="csv", check_exists=True),
            group=group_input_output,
        ),
        Parameter(
            name="Sample Base Directory",
            description="The directory where lookups for the files specified in the samplesheet will be made.",
            icon="far fa-folder",
            value=None,
            required=True,
            param_type=FileParamType(filetype="directory", check_exists=True),
            group=group_input_output,
        ),
        Parameter(
            name="Reference File",
            description="The reference that contains the gene or CDS of interest.",
            icon="fas fa-file-import",
            value=None,
            required=True,
            param_type=FileParamType(filetype="fasta", check_exists=True),
            group=group_input_output,
        ),
        # Operating Modes
        Parameter(
            name="Trim method",
            description=None,
            icon=None,
            value="MINIMAP2",
            required=False,
            param_type=SelectParamType(items=["MINIMAP2", "AGA", "CUSTOM"]),
            group=group_operating_modes,
        ),
        Parameter(
            name="Aligner",
            description="What aligner to use for the main alignment.",
            icon="fas fa-align-center",
            value="MAFFT",
            required=False,
            param_type=SelectParamType(
                items=[
                    "MAFFT",
                    "MAFFT-SEED",
                    "MUSCLE",
                    "PROBCONS",
                    "TCOFFEE",
                    "TCOFFEE_REGRESSIVE",
                    "PRANK",
                    "CLUSTAL_OMEGA",
                    "CLUSTALW",
                    "VIRULIGN",
                    "MACSE",
                    "VIRALMSA",
                    "PAGAN",
                ]
            ),
            group=group_operating_modes,
        ),
        Parameter(
            name="Multi timepoint alignment",
            description="This run should produce timepoint-stacked alignments.",
            icon=None,
            value=False,
            required=False,
            param_type=BoolParamType(),
            group=group_operating_modes,
        ),
        Parameter(
            name="Skip pre process",
            description=None,
            icon=None,
            value=False,
            required=False,
            param_type=BoolParamType(),
            group=group_operating_modes,
        ),
        Parameter(
            name="Skip functional filter",
            description=None,
            icon=None,
            value=False,
            required=False,
            param_type=BoolParamType(),
            group=group_operating_modes,
        ),
        Parameter(
            name="Skip trim",
            description=None,
            icon=None,
            value=False,
            required=False,
            param_type=BoolParamType(),
            group=group_operating_modes,
        ),
        # Custom Preprocess Arguments
        Parameter(
            name="Prs ts operating mode",
            description="What mode to use for trimming the sequences to the trimmed consensus.",
            icon="fas fa-broadcast-tower",
            value="double-match",
            required=False,
            param_type=SelectParamType(items=["single-match", "double-match"]),
            group=group_custom_preprocess,
        ),
        Parameter(
            name="Trim consensus alignment mode",
            description="What mode to use for aligning the consensus to the reference.",
            icon=None,
            value="local",
            required=False,
            param_type=SelectParamType(items=["local", "custom", "local_custom"]),
            group=group_custom_preprocess,
        ),
        Parameter(
            name="Trim consensus gap open penalty",
            description="The gap opening penalty to use for trimming to the consensus.",
            icon=None,
            value=5,
            required=False,
            param_type=BoolParamType(),
            group=group_custom_preprocess,
        ),
        Parameter(
            name="Trim consensus gap extension penalty",
            description="The gap extension penalty to use for trimming the consensus.",
            icon=None,
            value=1,
            required=False,
            param_type=IntParamType(None, None),
            group=group_custom_preprocess,
        ),
        # AGA Preprocess Arguments
        Parameter(
            name="Region of interest",
            description="The name of the CDS or protein that is to be extracted from the supplied files.",
            icon=None,
            value=None,
            required=True,
            param_type=StringParamType(255, None),
            group=group_aga_preprocess,
        ),
        Parameter(
            name="Region shorthand",
            description="What to shorten the region name to.",
            icon=None,
            value=None,
            required=False,
            param_type=StringParamType(255, None),
            group=group_aga_preprocess,
        ),
        # Minimap2 Trim Arguments
        Parameter(
            name="Minimap trim from",
            description=None,
            icon=None,
            value=None,
            required=False,
            param_type=IntParamType(None, None),
            group=group_minimap_trim,
        ),
        Parameter(
            name="Minimap trim to",
            description=None,
            icon=None,
            value=None,
            required=False,
            param_type=IntParamType(None, None),
            group=group_minimap_trim,
        ),
        # Filtering Options
        Parameter(
            name="Ff max stop pct",
            description="The maximum percentage along the read that a stop codon can find itself.",
            icon=None,
            value=100,
            required=False,
            param_type=IntParamType(None, None),
            group=group_filtering,
        ),
        Parameter(
            name="Ff include no stop codons",
            description="Allow sequences that do not contain any stop codons to be considered functional.",
            icon=None,
            value=True,
            required=False,
            param_type=BoolParamType(),
            group=group_filtering,
        ),
        Parameter(
            name="Ff include frameshifts",
            description="Include sequences that potentially contain a frameshift to be considered functional.",
            icon=None,
            value=False,
            required=False,
            param_type=BoolParamType(),
            group=group_filtering,
        ),
        Parameter(
            name="Ff acceptable pct loss",
            description="An acceptable proportion (0-1) of the median protein length that can be lost.",
            icon=None,
            value=0.2,
            required=False,
            param_type=FloatParamType(min_val=0, max_val=1),
            group=group_filtering,
        ),
        # Miscellaneous Process Arguments
        Parameter(
            name="Mafft args",
            description="Arguments to supply to MAFFT if using it as the aligner.",
            icon=None,
            value="--localpair --maxiterate 1000",
            required=False,
            param_type=StringParamType(255, None),
            group=group_misc_process,
        ),
        # Compute Options
        Parameter(
            name="Max memory",
            description="The maximum amount of memory to be allocated to a process.",
            icon=None,
            value="128.GB",
            required=False,
            param_type=StringParamType(255, None),
            group=group_compute,
        ),
        Parameter(
            name="Max cpus",
            description="The maximum number of CPU cores that can be allocated to a process.",
            icon=None,
            value=16,
            required=False,
            param_type=IntParamType(None, None),
            group=group_compute,
        ),
        Parameter(
            name="Max time",
            description="The maximum amount of time that a process can be allowed to run.",
            icon=None,
            value="240.h",
            required=False,
            param_type=StringParamType(255, None),
            group=group_compute,
        ),
        # Generic options
        Parameter(
            name="Run name",
            description="A human-readable identifier for this run.",
            icon="far fa-address-card",
            value=None,
            required=True,
            param_type=StringParamType(255, None),
            group=group_generic,
        ),
        # Other Parameters
        Parameter(
            name="Output dir",
            description="Directory to store results.",
            icon=None,
            value="./results/null",
            required=False,
            param_type=FileParamType(filetype="directory", check_exists=False),
            group=group_other,
        ),
    ]

    all_params = PipelineParams(groups, params)

    return all_params
