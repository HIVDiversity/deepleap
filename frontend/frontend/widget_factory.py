from pathlib import Path

from nicegui import ui
from nicegui.elements.mixins.color_elements import color
from typing_extensions import Optional

# Global styles?
input_label_style = "font-bold text-lg -mb-3"

expand_style = "w-full text-base border border-gray-400 rounded-md mb-3"
aligner_default_args = {
    "mafft": "--localpair --maxiterate 1000",
    "tcoffee": None,
    "tcoffee_regressive": "-nseq 100 -tree mbed -method clustalo_msa",
    "prank": "+F",
    "pagan": "",
    "clustalo": "--iterations 2",
    "clustalw": "-CLUSTERING=NJ -ITERATION=NONE -NUMITER=3 -MATRIX=BLOSUM",
    "virulign": "--maxFrameShifts 3 --exportReferenceSequence no",
    "macse": "",
    "viralmsa": "-a minimap2 --omit_ref",
}


def _form_label_help(
    label: str, help: Optional[str], input_label_style="font-bold text-lg gap-0"
):
    with ui.column().classes("gap-0"):
        ui.label(label).classes(input_label_style)
        if help:
            ui.markdown(help).classes("text-gray-600 gap-0")


def create_groups(form_values, upload_root):

    with ui.card_section().classes("w-full"):
        skip_trim, skip_preprocess, skip_functional_filter = create_general_group(
            form_values
        )

        create_input_output_group(form_values, upload_root)

        create_trimming_group(form_values, skip_trim)

        create_filtering_group(form_values)

        create_aligner_group(form_values)


def create_input_output_group(form_values: dict, upload_root: Path):
    """Creates the 'Input/output options' widget group."""
    with ui.expansion("Inputs", icon="terminal", value=False).classes(expand_style):
        ui.label("Provide samplesheet and input files.").classes("text-base")
        with ui.grid(columns=3, rows="auto"):
            with ui.column():
                ui.label("Samplesheet").classes(input_label_style)
                ui.label(
                    "The CSV file that specifies the various samples and metadata to feed into the pipeline. Expected: csv"
                ).classes("text-gray-600")

            with ui.column().classes("w-full"):
                ui.label("Sequence Files").classes(input_label_style)
                ui.label(
                    "All files to be processed by the pipeline. Note that these files must be described in the samplesheet above. Expected: FASTA"
                ).classes("text-gray-600")

            with ui.column():
                ui.label("Reference File").classes(input_label_style)
                ui.label(
                    "The reference sequence that will be used for trimming the region of interest. This can be different to the sequence used for mapping. Expected: FASTA"
                ).classes("text-gray-600")

            with ui.column():
                samplesheet_upload = (
                    ui.upload(
                        label="Upload Samplesheet *",
                        auto_upload=True,
                        on_upload=lambda f: upload_file(
                            f, upload_root, form_values, "samplesheet"
                        ),
                        on_rejected=lambda: ui.notify("Invalid file."),
                    )
                    .classes("w-full")
                    .props('color=deep-purple accept=".csv"')
                )

            with ui.column():
                seq_upload = (
                    ui.upload(
                        label="Files *",
                        multiple=True,
                        auto_upload=True,
                        on_multi_upload=lambda fs: upload_files(
                            fs.files, upload_root, form_values, "seqs"
                        ),
                        on_rejected=lambda: ui.notify(
                            "One or more invalid filetypes provided"
                        ),
                    )
                    .classes()
                    .classes("w-full")
                    .props('color=brown accept=".fasta, .fa, .fa"')
                )

            with ui.column():
                ref_seq_upload = (
                    ui.upload(
                        label="Reference Seq *",
                        on_upload=lambda f: upload_file(
                            f, upload_root, form_values, "ref_seq"
                        ),
                        auto_upload=True,
                        on_rejected=lambda: ui.notify("Invalid filetype provided"),
                    )
                    .classes("w-full")
                    .props('color=teal accept=".fasta, .fa, .fa"')
                )

        with ui.row():
            _form_label_help(
                "Alternate Reference",
                "Optionally, provide a different reference sequence to include with the sequences. This sequence will not be used for trimming, only for alignment. If not provided, the reference used in the trimming step is used.",
            )

            ui.upload(
                label="Additional Reference Seq",
                auto_upload=True,
                on_upload=lambda f: upload_file(
                    f, upload_root, form_values, "additional_ref"
                ),
            ).classes("w-full").props('color=grey accept=".fasta, .fa, .fa"')


async def upload_files(files, upload_root, form_values, key):
    form_values[key] = []
    for file in files:
        upload_loc = upload_root / file.name
        print(f"saving to {upload_loc}")
        await file.save(upload_loc)
        form_values[key].append(upload_loc)


async def upload_file(file, upload_root, form_values, key):
    upload_location = str(upload_root / file.file.name)
    await file.file.save(upload_location)
    form_values[key] = upload_location


def create_general_group(form_values):
    with ui.expansion("General", icon="settings", value=True).classes(expand_style):
        with ui.row().classes("w-full p-2"):
            _form_label_help("Run Name", None)
            ui.input(label="A short unique name for this run.").classes(
                "w-full -mt-2"
            ).bind_value_to(form_values, "run_name")

        with ui.row().classes("w-full p-2"):
            _form_label_help(
                "Skip Processing Steps", "Choose to skip certain steps of the pipeline."
            )
            with ui.row():
                with ui.column():
                    skip_trim = (
                        ui.switch("Skip Trimming", value=False)
                        .classes("w-full")
                        .bind_value_to(form_values, "skip_trim")
                    )

                with ui.column():
                    skip_preprocess = (
                        ui.switch("Skip Pre-Processing", value=False)
                        .classes("w-full")
                        .bind_value_to(form_values, "skip_preprocess")
                    )
                with ui.column():
                    skip_functional_filter = (
                        ui.switch("Skip Functional Filter", value=False)
                        .classes("w-full")
                        .bind_value_to(form_values, "skip_functional_filter")
                    )

        return skip_trim, skip_preprocess, skip_functional_filter


def create_trimming_group(form_values, skip_trim):
    with (
        ui.expansion("Trimming", icon="content_cut", value=False)
        .bind_visibility_from(skip_trim, "value", backward=lambda x: not x)
        .classes(expand_style)
    ):
        with ui.card().classes("w-full"):
            _form_label_help(
                "Trimming Method",
                "Choose the method that trims the region of interest.",
            )

            preprocess_select = (
                ui.select(
                    options=["MINIMAP2", "AGA"],
                    label="Trim method",
                    value="MINIMAP2",
                )
                .classes("w-full")
                .bind_value_to(form_values, "preprocess_method")
            )

        with ui.row().classes("w-full"):
            with (
                ui.card()
                .bind_visibility_from(
                    preprocess_select, "value", backward=lambda x: x == "AGA"
                )
                .classes("w-full")
            ):
                _form_label_help("AGA Parameters", "Configure `aga`-specific params.")

                with ui.grid(columns=2).classes("items-center"):
                    _form_label_help(
                        "Region of Interest",
                        "Provide the name of the region of interest as it appears in the GenBank file. No validation is performed on this, so ensure it is exactly correct.",
                        "text-m font-bold",
                    )

                    region_name = (
                        ui.input()
                        .classes("w-full")
                        .props("outlined rounded")
                        .bind_value_to(form_values, "aga_params")
                    ).bind_value_to(form_values, "region_name")

                with ui.grid(columns=2).classes("items-center"):
                    _form_label_help(
                        "Region Shorthand",
                        "If desired, provide an alternate short form of the region, e.g `'envelope' -> 'ENV'`.",
                        "text-m font-bold",
                    )

                    ui.input().classes("w-full").props(
                        "outlined rounded"
                    ).bind_value_from(
                        region_name, "value", backward=lambda x: x[:3].upper()
                    ).bind_value_to(form_values, "region_name_shorthand")

        with ui.row().classes("w-full"):
            with (
                ui.card()
                .bind_visibility_from(
                    preprocess_select, "value", backward=lambda x: x == "MINIMAP2"
                )
                .classes("w-full")
            ):
                _form_label_help(
                    "Minimap2 Parameters", "Configure `minimap2`-specific parameters."
                )

                ui.label(
                    "Specify the start and end coordinates on the reference sequence that define your region of interest. Both values are inclusive."
                )
                with ui.grid(columns=2):
                    ui.number(label="RoI Start*", step=1, precision=0, min=0).classes(
                        "w-full"
                    ).bind_value_to(form_values, "minimap_roi_start")
                    ui.number(label="RoI End*", step=1, precision=0, min=0).classes(
                        "w-full"
                    ).bind_value_to(form_values, "minimap_roi_end")


def create_aligner_group(form_values):
    with ui.expansion("Alignment", icon="subject", value=False).classes(expand_style):
        with ui.column():
            _form_label_help(
                "Aligner",
                "Choose which aligner to use to perform the main MSA. For assistance, see the help page for the differences between each tool.",
            )

            aligner_select = (
                ui.select(
                    options=[
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
                    ],
                    value="MAFFT",
                )
                .classes("w-full")
                .props("rounded outlined")
            ).bind_value_to(form_values, "aligner")
        with ui.expansion(
            "Advanced Aligner Params",
            icon="tune",
            caption="Only edit these if you know what you're doing.",
            value=True,
        ).classes("w-full"):
            with ui.row():
                _form_label_help(
                    "Aligner Argument",
                    "These args are passed to the aligner of your choice as-is. They may cause a crash in the system.",
                )
                param_default = None
                ui.input(
                    label="Aligner args",
                    value="--localpair --maxiterate 1000",
                ).classes("w-full").tooltip(
                    "Arguments to supply to MAFFT if using it as the aligner."
                ).bind_value_to(form_values, "aligner_params")

            with ui.row():
                _form_label_help(
                    "Add Reference to Alignment",
                    "Choose how the provided reference is added to the alignment.",
                )

                ui.select(
                    options={
                        "none": "Do not add the reference to the alignment",
                        "BEFORE": "Add reference BEFORE alignment",
                        "AFTER": "Add reference AFTER alignment",
                    },
                    value="none",
                ).classes("w-full").props("rounded outlined").bind_value_to(
                    form_values, "add_ref_to_seqs"
                )

    pass


# def create_custom_preprocess_group(form_values):
#     """Creates the 'Custom Preprocess Arguments' widget group."""

#     with ui.expansion(
#         "Custom Preprocess Arguments", icon="fas fa-frog", value=True
#     ).classes("w-full"):
#         ui.label("Arguments for the CUSTOM preprocessing mode.").classes(
#             "text-sm text-gray-600 ml-1"
#         )
#         ui.select(
#             options=["single-match", "double-match"],
#             label="Prs ts operating mode",
#             value="double-match",
#         ).classes("w-full").tooltip(
#             "What mode to use for trimming the sequences to the trimmed consensus."
#         )
#         ui.select(
#             options=["local", "custom", "local_custom"],
#             label="Trim consensus alignment mode",
#             value="local",
#         ).classes("w-full").tooltip(
#             "What mode to use for aligning the consensus to the reference."
#         )
#         ui.number(
#             label="Trim consensus gap open penalty",
#             value=5,
#             step=1,
#             precision=0,
#         ).classes("w-full").tooltip(
#             "The gap opening penalty to use for trimming to the consensus."
#         )
#         ui.number(
#             label="Trim consensus gap extension penalty",
#             value=1,
#             step=1,
#             precision=0,
#         ).classes("w-full").tooltip(
#             "The gap extension penalty to use for trimming the consensus."
#         )


# def create_aga_preprocess_group():
#     # """Creates the 'AGA Preprocess Arguments' widget group."""
#     # with ui.expansion(
#     #     "AGA Preprocess Arguments", icon="fas fa-cat", value=True
#     # ).classes("w-full"):
#     #     ui.label("Arguments for the AGA preprocessing strategy.").classes(
#     #         "text-sm text-gray-600 ml-1"
#     #     )
#     #     ui.input(label="Region of interest *").classes("w-full").tooltip(
#     #         "The name of the CDS or protein that is to be extracted from the supplied files."
#     #     )
#     #     ui.input(label="Region shorthand").classes("w-full").tooltip(
#     #         "What to shorten the region name to."
#     #     )
#     #
#     pass


# def create_minimap_trim_group():
#     # """Creates the 'Minimap2 Trim Arguments' widget group."""
#     # with ui.expansion(
#     #     "Minimap2 Trim Arguments", icon="fas fa-map-marked-alt", value=True
#     # ).classes("w-full"):
#     #     ui.label("Arguments specifying how minimap2 must trim sequences.").classes(
#     #         "text-sm text-gray-600 ml-1"
#     #     )
#     #     ui.number(label="Minimap trim from", step=1, precision=0).classes("w-full")
#     #     ui.number(label="Minimap trim to", step=1, precision=0).classes("w-full")
#     pass


def create_filtering_group(form_values):
    """Creates the 'Filtering Options' widget group."""
    with ui.expansion("Filtering Options", icon="filter_alt", value=False).classes(
        expand_style
    ):
        _form_label_help(
            "Stop Codon Position",
            "The minimum percentage from the start of a sequence that a stop codon may lie, below which a sequence is deemed non-functional.",
        )
        svg_item = Path("assets/codon_distance_help.svg").read_text()

        ui.number(
            label="Min acceptable distance (percentage)",
            value=100,
            step=1,
            precision=0,
        ).classes("w-full").tooltip(
            "The maximum percentage along the read that a stop codon can find itself."
        ).bind_value_to(form_values, "ff_max_stop_pct")

        # ui.html(svg_item, sanitize=False).classes("w-full")

        _form_label_help(
            "Frame Shifts and Stop Codons",
            None,
        )
        ui.switch("Include sequences with no stop codons.", value=True).classes(
            "w-full"
        ).tooltip(
            "Allow sequences that do not contain any stop codons to be considered functional."
        ).bind_value_to(form_values, "ff_include_no_stop_codons")
        ui.switch("Include sequences that contain frameshifts", value=False).classes(
            "w-full"
        ).tooltip(
            "Include sequences that potentially contain a frameshift to be considered functional."
        ).bind_value_to(form_values, "ff_include_frameshifts")

        _form_label_help(
            "Sequence Length",
            "The proportion of a sequence compared to the median sequence length that may be lost before a sequence is considered non-functional. For example, a value of 0.2 means that a sequence may differ by up to 20% from the median sequence length before being classified as non-functional.",
        )
        ui.number(
            label="Proportion of Sequence Length Loss",
            value=0.2,
            min=0,
            max=1,
            step=0.01,
        ).classes("w-full").tooltip(
            "An acceptable proportion (0-1) of the median protein length that can be lost."
        ).bind_value_to(form_values, "ff_max_seq_loss")
        ui.label(
            "If you know the expected length of the gene region you have provided, you can enter it below. If the value in this box is not 0, that length with be used instead of the median value in the filtering step described above."
        )
        ui.number(label="Expected sequence length", min=0, value=0).classes(
            "w-full"
        ).tooltip(
            "An acceptable proportion (0-1) of the median protein length that can be lost."
        ).bind_value_to(form_values, "ff_expected_length")


def create_compute_group():
    """Creates the 'Compute Options' widget group."""
    with ui.expansion("Compute Options", icon="fas fa-desktop", value=True).classes(
        "w-full"
    ):
        ui.label("Parameters affecting computational resources.").classes(
            "text-sm text-gray-600 ml-1"
        )
        ui.input(
            label="Max memory",
            value="128.GB",
        ).classes("w-full").tooltip(
            "The maximum amount of memory to be allocated to a process."
        )
        ui.number(
            label="Max cpus",
            value=16,
            step=1,
            precision=0,
        ).classes("w-full").tooltip(
            "The maximum number of CPU cores that can be allocated to a process."
        )
        ui.input(
            label="Max time",
            value="240.h",
        ).classes("w-full").tooltip(
            "The maximum amount of time that a process can be allowed to run."
        )
