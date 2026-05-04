import os
import shutil
import subprocess
from pathlib import Path


def codex_available():
    return shutil.which("codex") is not None


def load_prompt(path):
    path = Path(path)
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")


def load_prompt_template(path):
    return load_prompt(path)


def codex_run(prompt, fallback_text, timeout_seconds=300):
    return run_codex(prompt, fallback_text, timeout_seconds)


def run_codex(prompt, fallback_text, timeout_seconds=300):
    """
    Run Codex in non-interactive mode.

    If DISABLE_CODEX=1, Codex is not installed, or Codex fails,
    return the rule-based fallback report instead.
    """

    if os.getenv("DISABLE_CODEX", "0") == "1":
        return fallback_text

    if not codex_available():
        return (
            fallback_text
            + "\n\n---\n"
            + "Codex was not available, so this report used the local rule-based fallback.\n"
        )

    try:
        result = subprocess.run(
            ["codex", "exec", prompt],
            text=True,
            capture_output=True,
            timeout=timeout_seconds,
            check=False,
        )

        if result.returncode != 0:
            return (
                fallback_text
                + "\n\n---\n"
                + "Codex execution failed. Falling back to rule-based report.\n\n"
                + "```text\n"
                + result.stderr[-3000:]
                + "\n```\n"
            )

        return result.stdout.strip()

    except Exception as exc:
        return (
            fallback_text
            + "\n\n---\n"
            + f"Codex execution failed with exception: `{exc}`.\n"
        )