import os
from pathlib import Path
from google import genai
from google.genai import types


def load_prompt(path):
    path = Path(path)
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")


def load_prompt_template(path):
    return load_prompt(path)


def _safe_rtl_path(filename: str):
    """
    Resolve and validate a path under src/rtl.
    Returns (ok, path_or_error).
    """
    rtl_dir = Path("src/rtl").resolve()
    requested = (rtl_dir / filename).resolve()

    if rtl_dir not in requested.parents and requested != rtl_dir:
        return False, "Error: Refusing to access files outside src/rtl."

    if requested.suffix not in [".sv", ".v"]:
        return False, "Error: Only .sv and .v RTL files may be accessed."

    return True, requested


def read_verilog_file(filename: str) -> str:
    """
    Reads a SystemVerilog/Verilog file from src/rtl.

    Use this tool when a simulation, synthesis, or lint log mentions
    a specific RTL file and source context is needed before suggesting a fix.
    """
    ok, result = _safe_rtl_path(filename)
    if not ok:
        return result

    requested = result

    if not requested.exists():
        return f"Error: Could not find file {requested}."

    return requested.read_text(errors="ignore")

def write_verilog_file(filename: str, content: str) -> str:
    """
    Writes a SystemVerilog/Verilog file under src/rtl.

    Use only in AUTO_REPAIR mode after identifying a concrete RTL bug.
    Do not rewrite unrelated files.
    """
    if os.getenv("AUTO_REPAIR", "0") != "1":
        return "Error: AUTO_REPAIR is not enabled. Refusing to write RTL files."

    ok, result = _safe_rtl_path(filename)
    if not ok:
        return result

    requested = result

    if not requested.exists():
        return f"Error: Could not find file {requested}. Refusing to create new RTL files."

    backup_path = requested.with_suffix(requested.suffix + ".bak")
    backup_path.write_text(requested.read_text(errors="ignore"))

    # Verilator requires a POSIX newline at EOF.
    content = content.rstrip() + "\n"

    requested.write_text(content)

    return f"Updated {requested}. Backup written to {backup_path}."

def gemini_run(prompt, fallback_text):
    """
    Run Gemini via the official Google Gen AI Python SDK with agentic tool calling.
    """
    if os.getenv("DISABLE_GEMINI", "0") == "1":
        return (
            fallback_text
            + "\n\n---\n"
            + "Gemini disabled via DISABLE_GEMINI=1. "
            + "This report used the local rule-based fallback without agentic tool calling.\n"
        )

    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return (
            fallback_text
            + "\n\n---\n"
            + "GOOGLE_API_KEY was not found. "
            + "This report used the local rule-based fallback without agentic tool calling.\n"
        )

    try:
        client = genai.Client(api_key=api_key)

        model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        auto_repair = os.getenv("AUTO_REPAIR", "0") == "1"

        agent_tools = [read_verilog_file]

        if auto_repair:
            agent_tools.append(write_verilog_file)

        repair_mode_note = (
        "\n\nAUTO_REPAIR mode is ENABLED. "
        "You may use write_verilog_file only for a minimal, concrete RTL bug fix. "
        "Do not rewrite unrelated modules. Preserve module ports."
        if auto_repair
        else
        "\n\nAUTO_REPAIR mode is DISABLED. "
        "Do not modify files. Only generate analysis and suggested patches."
        )

        config = types.GenerateContentConfig(
            tools=agent_tools,
            temperature=0.1,
        )

        chat = client.chats.create(
            model=model,
            config=config,
        )

        response = chat.send_message(prompt + repair_mode_note)

        if not response.text:
            return (
                fallback_text
                + "\n\n---\n"
                + "Gemini execution failed: response was empty or blocked by safety filters.\n"
            )

        return response.text.strip()

    except Exception as exc:
        return (
            fallback_text
            + "\n\n---\n"
            + f"Gemini execution failed with exception: `{exc}`.\n"
        )