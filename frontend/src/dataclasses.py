from attrs import define
from typing import Optional, List
from enum import Enum


@define
class Group:
    name: str
    description: Optional[str]
    icon: Optional[str]


class ParamType(Enum):
    string = 0
    BOOL = 1
    INT = 2
    SELECT = 3


@define
class StringParamType:
    length: int
    regex: Optional[str]


@define
class IntParamType:
    max_val: Optional[int]
    min_val: Optional[int]


@define
class SelectParamType:
    items = List[str]


@define
class FileParamType:
    filetype: str
    check_exists: bool


type ParamConfigType = StringParamType | IntParamType | SelectParamType | FileParamType
type AnyParamType = str | int | bool


@define
class Parameter:
    name: str
    description: str
    icon: Optional[str]
    value: Optional[AnyParamType]
    required: bool
    param_type: ParamType
    param_config: ParamConfigType
    group: Group


@define
class PipelineParams:
    groups: List[Group]
    parameters: List[Parameter]


# "input_output_options": {
#       "title": "Input/output options",
#       "type": "object",
#       "fa_icon": "fas fa-terminal",
#       "description": "Define where the pipeline should find input data and save output data.",
#       "required": ["samplesheet", "sample_base_dir", "reference_file"],
#       "properties": {
#         "samplesheet": {
#           "type": "string",
#           "description": "The CSV file that specifies the various samples and metadata to feed into the pipeline",
#           "format": "file-path",
#           "mimetype": "text/csv",
#           "fa_icon": "fas fa-file-csv"
#         },
#         "sample_base_dir": {
#           "type": "string",
#           "fa_icon": "far fa-folder",
#           "description": "The directory where lookups for the files specified in the samplesheet will be made",
#           "format": "directory-path"
#         },
#         "reference_file": {
#           "type": "string",
#           "fa_icon": "fas fa-file-import",
#           "description": "The reference that contains the gene or CDS of interest. Note that this file type depends on the pre-processing mode selected.",
#           "format": "file-path"
#         }
#       }
#     },
