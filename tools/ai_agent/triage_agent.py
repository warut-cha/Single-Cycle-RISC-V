from pathlib import Path
import re

from tools.common.file_utils import read_text, write_text
from tools.common.codex_client import codex_run, load_prompt

SIM_LOG = "reports/sim/sim_log.txt"
LINT_LOG = "reports/lint/lint_log.txt"
SYTH_LOG = "reports/synthesisesis/synth_log.txt"
OUT_REPORT = "reports/ai/triage_report.md"

def status_from_log(
    log:str
) -> str:
    lower = log.lower()

    if "[missing file:" in lower:
        return "MISSING"

    if not lower.strip():
        return "EMPTY"

    if "error" in lower or "%error" in lower or "failed" in lower or "fatal" in lower:
        return "FAIL"
    if "fail:" in lower or "fail" in lower:
        return "FAIL"
    if "pass" in lower or "executed" in lower or "finish called" in lower:
        return "PASS"

    return "UNKNOWN"    

def extract_verilator(
    log:str
):
    pattern = r"%(Warning|Error|Info)+([A-Za-z0-9_]+):\s+([^:]+):(\d+):\d+:\s+(.*)"
    return re.findall(pattern, log)

def classify_warning(
    warning:str
) -> str:
    functional = {"UNDRIVEN", "WIDTHTRUNC", "LATCH", "MULTIDRIVEN", "UNOPTFLAT"}
    style = {"EOFNEWLINE", "UNUSEDSIGNAL", "BLKSEQ"}

    if warning in functional:
        return "Functional risk"
    if warning in style:
        return "Style/quality"
    return "Review needed"

def build_rule_based_report(
    sim_log:str,
    lint_log:str,
    synth_log:str,
) -> str:
    findings = extract_verilator(lint_log)
    report = []
    report.append("## Status Summary\n")
    report.append(f"- Simulation: **{status_from_log(sim_log)}**")
    report.append(f"- Linting: **{status_from_log(lint_log)}**")
    report.append(f"- Synthesis: **{status_from_log(synth_log)}**\n")


    report.append("\n## Verilator Findings\n")
    if findings:
        for severity, kind, file_name, line_no, message in findings:
            report.append(f"- **{severity}-{kind}** in `{file_name}:{line_no}`")
            report.append(f"  - Classification: {classify_warning(kind)}")
            report.append(f"  - Message: {message}")
    else:
        report.append("- No Verilator warnings/errors detected.")
    
    report.append("\n## Simulation Log Excerpt\n")
    report.append("```text")
    report.append(sim_log[-1500:] if sim_log else "No simulation log available.")
    report.append("```\n")

    report.append("\n## Suggested Debug Prio\n")

    prio = []

    if "UNDRIVEN" in lint_log:
        prio.append("Fix undriven signals first because they often cause X propagation.")
    if "WIDTHTRUNC" in lint_log:
        prio.append("Fix width truncation warnings because they can cause incorrect addressing or data loss.")
    if "LATCH" in lint_log:
        prio.append("Fix inferred latch warnings by adding complete default assignments.")
    if "BLKSEQ" in lint_log:
        prio.append("Review blocking assignments in sequential logic.")
    if "x" in sim_log.lower():
        prio.append("Investigate X propagation in simulation and add strict `!==` checks.")
    if "%Error" in synth_log or "ERROR:" in synth_log:
        prio.append("Fix synthesis errors before trusting area/netlist reports.")

    if prio:
        for idx, item in enumerate(prio, 1):
            report.append(f"{idx}. {item}")
    else:
        report.append("- No specific issues detected, but review the simulation log for any unexpected behavior.")
    
    report.append("\n## Recommended Regression Additions\n")
    report.append("- Add explicit PASS/FAIL checks in `tb/top_tb.sv`.")
    report.append("- Fail the test if any observed register is X/Z.")
    report.append("- Add one directed test for each supported instruction.")
    report.append("- Save VCD waveforms as CI artifacts only on failure.")

    return "\n".join(report)

def main():
    sim_log = read_text(SIM_LOG)
    lint_log = read_text(LINT_LOG)
    synth_log = read_text(SYTH_LOG)
    fallback = build_rule_based_report(sim_log, lint_log, synth_log)
    prompt = load_prompt("tools/ai_agent/triage_prompt.md")

    prompt = f"""
    {prompt}
    Repository context:
    This is a SystemVerilog single-cycle RISC-V CPU project with Icarus simulation,
    Verilator linting, and Yosys synthesis.

    Simulation log:
    ```text
    {sim_log[-6000:]}

    Verilator lint log:
    {lint_log[-6000:]}

    Synthesis log:
    {synth_log[-6000:]}

    Generate a markdown triage report. 
    Do not invent files, warning, or signal that are not present in the logs.
    """
    report = codex_run(prompt, fallback)
    write_text(OUT_REPORT, report)
    print(f"Generated {OUT_REPORT}")

if __name__ == "__main__":
    main()

