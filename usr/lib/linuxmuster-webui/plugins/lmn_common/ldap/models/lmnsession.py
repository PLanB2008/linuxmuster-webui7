from dataclasses import dataclass
from datetime import datetime

@dataclass
class LMNSession:
    sid: str
    name: str
    participants: list
