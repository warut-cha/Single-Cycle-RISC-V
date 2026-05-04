from pathlib import Path
from typing import Iterable

def read_text(
    path: str | Path,
    max_length: int | None = None,
) -> str:

    path = Path(path)
    if not path.exists():
        return f"[Missing file: {path}]"
    
    text = path.read_text(errors="ignore")
    if max_length is not None and len(text) > max_length:
        return text[:max_length]
    return text

def write_text(
    path: str | Path,
    text: str,
) -> None:
    
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)

def read_glob(
    pattern: str,
    max_chars_per_file: int | None = None,
) -> str:
    output = []
    for path in sorted(Path(".").glob(pattern)):
        if path.is_file():
            output.append(read_text(path, max_length=max_chars_per_file))
    
    if not output:
        raise FileNotFoundError(f"No files found matching pattern: {pattern}")
    return "\n".join(output)

def ensure_dirs(
    path: Iterable[str | Path],
) -> None:
    for p in path:
        Path(p).mkdir(parents=True, exist_ok=True)