import asyncio
import json
import shlex
import subprocess
import tomllib
import uuid
from datetime import datetime
from pathlib import Path
from string import Template

from frontend import config, db, models


async def create_pipeline_run(
    params: dict, optional_params: dict, run_id: str, run_root: Path
):
    engine = db.get_engine()
    db_param_dump = params.copy()
    db_param_dump["optional_params"] = optional_params
    with db.Session(engine) as session:
        pipeline_run = models.PipelineRun(
            id=run_id,
            name=params["run_name"],
            status="pending",
            started_at=datetime.now(),
            finished_at=None,
            root_foler=str(run_root),
            ref_file=str(params["ref_file"].name),
            # config=json.dumps(db_param_dump),
        )
        session.add(pipeline_run)
        session.commit()
        session.refresh(pipeline_run)

    run_command = build_command(params, optional_params, run_root)
    process = await asyncio.create_subprocess_exec(
        *shlex.split(run_command),
        stdout=open(run_root / "pipeline.log", "wb"),
        stderr=asyncio.subprocess.STDOUT,
    )

    await process.communicate()

    if process.returncode == 0:
        final_status = "success"
    else:
        final_status = "failed"

    with db.Session(engine) as session:
        pipeline_run = session.get(models.PipelineRun, run_id)
        if pipeline_run:
            pipeline_run.status = final_status
            pipeline_run.finished_at = datetime.now()
            session.add(pipeline_run)
            session.commit()
            session.refresh(pipeline_run)


def build_command(params: dict, optional_params, run_root: Path):
    command = Template(
        "$nextflow -log $nextflow_log run -c $nextflow_config $main_nf --run_name $run_name --samplesheet $samplesheet --reference_file $ref_file --aligner $aligner -profile docker --region_of_interest $region_of_interest --trim_method $trim_method --sample_base_dir $sample_base_dir -output-dir $output_dir -work-dir $nextflow_work_dir --max_memory $max_memory --max_cpus $max_cpus --max_time $max_time $other_flags "
    )
    config_values = config.get_config()

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

    return command_hydrated


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
