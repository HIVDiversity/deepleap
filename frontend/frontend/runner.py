import asyncio
import shlex
import subprocess
import tomllib
from pathlib import Path
from string import Template


async def run_pipeline(params: dict, optional_params):
    command = Template(
        "$nextflow -log $nextflow_log run -c $nextflow_config $main_nf --run_name $run_name --samplesheet $samplesheet --reference_file $ref_file --aligner $aligner -profile docker --region_of_interest $region_of_interest --trim_method $trim_method --sample_base_dir $sample_base_dir -output-dir $output_dir -work-dir $nextflow_work_dir --max_memory $max_memory --max_cpus $max_cpus --max_time $max_time $other_flags "
    )
    with open("config.toml", "rb") as f:
        config_values = tomllib.load(f)

    command_hydrated = command.substitute(
        nextflow=config_values["nextflow_binary"],
        nextflow_log=config_values["nextflow_log_path"],
        nextflow_config=config_values["nextflow_config_file"],
        main_nf=config_values["nextflow_main_script"],
        nextflow_work_dir=config_values["nextflow_work_dir"],
        max_memory=config_values["max_memory"],
        max_cpus=config_values["max_cpus"],
        max_time=config_values["max_time"],
        other_flags=build_optional_param_string(optional_params),
        **params,
    )

    print(command_hydrated)
    process = await asyncio.create_subprocess_exec(
        *shlex.split(command_hydrated),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )

    return await process.wait()


def build_optional_param_string(optional_params):
    mapping = {
        "aligner_params": "",
        "ff_max_stop_pct": Template("--ff_max_stop_pct $value"),
        "ff_include_frameshifts": "--ff_include_frameshifts",
        "ff_max_seq_loss": Template("--ff_acceptable_pct_loss $value"),
        "ff_include_no_stop_codons": "--ff_include_no_stop_codons",
        "minimap_roi_start": Template("--minimap_trim_from $value"),
        "ff_expected_length": Template("--ff_expected_length $value"),
        "minimap_roi_end": Template("--minimap_trim_to $value"),
        "additional_ref": Template("--reference_to_add $value"),
        "skip_trim": "--skip_trim",
        "skip_preprocess": "--skip_pre_process",
        "skip_functional_filter": "--skip_functional_filter",
        "region_name_shorthand": Template("--region_shorthand $value"),
        "add_reference_to_sequences": Template("--add_reference_to_sequences $value"),
    }

    optional_param_strings = []

    for param, value in optional_params.items():
        template_string = mapping[param]
        if value:
            if isinstance(template_string, Template):
                if param == "add_reference_to_sequences":
                    if value:
                        optional_param_strings.append(
                            template_string.substitute(value=value)
                        )
                else:
                    optional_param_strings.append(
                        template_string.substitute(value=value)
                    )
            elif isinstance(template_string, str):
                if value:
                    optional_param_strings.append(template_string)

    return " ".join(optional_param_strings)
