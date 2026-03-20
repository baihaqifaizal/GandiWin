from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Result:
    success: bool
    message: str
    error: Optional[str] = None
    data: Optional[dict] = field(default_factory=dict)

    @classmethod
    def ok(cls, message: str = "Berhasil") -> "Result":
        return cls(success=True, message=message)

    @classmethod
    def fail(cls, error: str, message: str = "Gagal") -> "Result":
        return cls(success=False, message=message, error=error)

    @classmethod
    def warn(cls, message: str) -> "Result":
        return cls(success=False, message=message)

    @classmethod
    def dry_run(cls, tweak: dict) -> "Result":
        return cls(success=True, message=f"[DRY RUN] {tweak['type']} → {tweak['id']}")
