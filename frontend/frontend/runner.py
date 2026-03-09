import asyncio
import json
import shlex
import subprocess
import tomllib
import uuid
from datetime import datetime
from pathlib import Path
from string import Template

from loguru import logger
from typing_extensions import Optional

from frontend import config, db, models


def add_new_run_to_db(params, optional_params, run_id, run_root, run_command):

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
            root_folder=str(run_root),
            ref_file=str(params["ref_file"].name),
            run_command=run_command,
            # config=json.dumps(db_param_dump),
        )
        session.add(pipeline_run)
        session.commit()
        session.refresh(pipeline_run)

    logger.info(f"Pipeline run {run_id} created in database with status 'pending'.")

    return pipeline_run


def update_run_status(run_id: str, new_status: str):
    engine = db.get_engine()
    with db.Session(engine) as session:
        pipeline_run = session.get(models.PipelineRun, run_id)
        if pipeline_run:
            pipeline_run.status = new_status
            pipeline_run.finished_at = datetime.now()
            session.add(pipeline_run)
            session.commit()
            session.refresh(pipeline_run)
    logger.info(f"Pipeline run {run_id} status updated to '{new_status}' in database.")

    return pipeline_run


async def create_pipeline_run(
    params: dict, optional_params: dict, run_id: str, run_root: Path
):
    logger.info(f"Creating pipeline run with ID {run_id} at {run_root}.")
    run_command = build_command(params, optional_params, run_root)
    pipeline_run = add_new_run_to_db(
        params, optional_params, run_id, run_root, run_command
    )

    pipeline_retrun_code = await run_pipeline_command(run_command, run_root, run_id)

    if pipeline_retrun_code == 0:
        final_status = "success"
    else:
        final_status = "failed"

    pipeline_run = update_run_status(run_id, final_status)

    return pipeline_run


async def create_pipeline_rerun(old_run_id: str):
    engine = db.get_engine()
    with db.Session(engine) as session:
        old_run = session.get(models.PipelineRun, old_run_id)
        if not old_run:
            logger.error(f"Old run with ID {old_run_id} not found in database.")
            return
        old_run_command = old_run.run_command

        old_run.finished_at = None
        old_run.status = "pending"
        old_run.started_at = datetime.now()
        session.add(old_run)
        session.commit()
        session.refresh(old_run)

    logger.info(f"Created rerun for old run {old_run_id}.")
    pipeline_run_status = await run_pipeline_command(
        old_run_command, Path(old_run.root_folder), old_run_id
    )

    if pipeline_run_status == 0:
        final_status = "success"
    else:
        final_status = "failed"

    new_run = update_run_status(old_run_id, final_status)

    return new_run


async def run_pipeline_command(run_command: str, run_root: Path, run_id: str):
    logger.info(f"Running pipeline command: {run_command}")
    logger.info(
        "Including env variables: " + config.get_config().get("env", {}).__str__()
    )

    with open(run_root / "pipeline_run.sh", "w") as f:
        f.write(run_command)

    process = await asyncio.create_subprocess_exec(
        # *shlex.split(run_command),
        "/bin/bash",
        str(run_root / "pipeline_run.sh"),
        stdout=open(run_root / "pipeline.log", "wb"),
        stderr=asyncio.subprocess.STDOUT,
        env=config.get_config().get("env"),
    )

    await process.communicate()
    logger.info(
        f"Pipeline process for run {run_id} completed with return code {process.returncode}."
    )

    return process.returncode


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

    for env_var in config_values.get("env", {}):
        command_hydrated = (
            f"export {env_var}={config_values['env'][env_var]} \n" + command_hydrated
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
