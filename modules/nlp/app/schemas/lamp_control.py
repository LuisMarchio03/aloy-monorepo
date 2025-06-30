from pydantic import BaseModel
from typing import Literal, Optional

class LampControlData(BaseModel):
    action: Literal["turn_on", "turn_off", "set_color", "set_intensity"]
    room: str
    color: Optional[str] = None
    intensity: Optional[str] = None

class LampControlCommand(BaseModel):
    type: Literal["lamp_control"]
    message: str
    data: LampControlData
