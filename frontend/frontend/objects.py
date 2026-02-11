from enum import Enum
from typing import List, Optional

from attrs import define


@define
class Group:
    name: str
    description: Optional[str]
    icon: Optional[str]


class ParamType(Enum):
    STRING = 0
    BOOL = 1
    INT = 2
    SELECT = 3
    FILE = 4
    FLOAT = 5


@define
class StringParamType:
    length: int
    regex: Optional[str]


@define
class IntParamType:
    max_val: Optional[int]
    min_val: Optional[int]


@define
class FloatParamType:
    max_val: Optional[float]
    min_val: Optional[float]


@define
class SelectParamType:
    items: List[str]


@define
class FileParamType:
    filetype: str
    check_exists: bool


@define
class BoolParamType:
    pass


type ParamConfigType = (
    StringParamType
    | IntParamType
    | SelectParamType
    | FileParamType
    | FloatParamType
    | BoolParamType
)
type AnyParamType = str | int | bool | float


@define
class Parameter:
    name: str
    description: Optional[str]
    icon: Optional[str]
    value: Optional[AnyParamType]
    required: bool
    param_type: ParamConfigType
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
