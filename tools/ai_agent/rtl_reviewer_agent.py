from pathlib import Path
import re

from tools.common.file_utils import read_glob, write_text
from tools.common.codex_client import run_codex, load_prompt_template


OUT_REPORT = "reports/ai/rtl_review_report.md"


def find_blocking_assignments_in_sequential(rtl_text: str):
    findings = []

    file_blocks = re.split(r"\n===== FILE: ", rtl_text)

    for block in file_blocks:
        if not block.strip():
            continue

        first_line, *rest = block.splitlines()
        file_name = first_line.replace("=====", "").strip()
        text = "\n".join(rest)

        sequential_blocks = re.findall(
            r"always\s*@\s*\([^)]*posedge[^)]*\)\s*begin(.*?)end",
            text,
            flags=re.DOTALL,
        )

        for seq_block in sequential_blocks:
            # Naive but useful. Ignores <=, ==, !=, >=, <=.
            if re.search(r"(?<![<>=!])=(?!=)", seq_block):
                findings.append(
                    f"- `{file_name}`: possible blocking assignment inside clocked/sequential logic."
                )

    return findings


def find_case_without_default(rtl_text: str):
    findings = []

    file_blocks = re.split(r"\n===== FILE: ", rtl_text)

    for block in file_blocks:
        if not block.strip():
            continue

        first_line, *rest = block.splitlines()
        file_name = first_line.replace("=====", "").strip()
        text = "\n".join(rest)

        case_blocks = re.findall(r"case\s*\(.*?\)(.*?)endcase", text, flags=re.DOTALL)

        for case_block in case_blocks:
            if "default" not in case_block:
                findings.append(f"- `{file_name}`: `case` statement may be missing `default`.")

    return findings


def build_rule_based_report(rtl_text: str) -> str:
    findings = []
    findings.extend(find_blocking_assignments_in_sequential(rtl_text))
    findings.extend(find_case_without_default(rtl_text))

    report = []
    report.append("# RTL Code Review Report\n")

    report.append("## Rule-Based Style Findings\n")
    if findings:
        report.extend(findings)
    else:
        report.append("- No simple rule-based RTL style findings detected.")

    report.append("\n## Recommended SystemVerilog Assertions\n")
    report.append("Add these to a simulation-only assertion file such as `tb/assertions.sv`.\n")

    report.append("""```systemverilog
    // PC should always be word-aligned.
    assert property (@(posedge clk) disable iff (rst)
        pc_out[1:0] == 2'b00
    );

    // Register x0 must remain zero.
    assert property (@(posedge clk) disable iff (rst)
        dut.regfile_instance.registers[0] == 32'b0
    );

    // Data memory write enable should only be active for store instructions.
    assert property (@(posedge clk) disable iff (rst)
        ram_write_enable |-> opcode_out == 7'b0100011
    );

    // Register writeback data should not be unknown when write enable is active.
    assert property (@(posedge clk) disable iff (rst)
        reg_write_enable |-> !$isunknown(write_data)
    );
    ```""")

    report.append("\n## Manual Review Checklist\n")
    report.append("- Confirm `ADD`, `SUB`, and `MUL` decode use correct RISC-V `funct7` values.")
    report.append("- Confirm memories use `address[11:2]` for a 1024-word word-addressed memory.")
    report.append("- Confirm all combinational decode blocks have default assignments.")
    report.append("- Confirm all sequential logic uses non-blocking assignments.")
    report.append("- Confirm `x0` writes are ignored in the register file.")
    report.append("- Confirm reset behavior is documented and tested.")

    return "\n".join(report)


def main():
    rtl_text = read_glob("src/rtl/*.sv", max_chars_per_file=12000)
    fallback = build_rule_based_report(rtl_text)

    prompt_template = load_prompt_template("tools/rtl_agents/prompts/rtl_review.md")

    prompt = f"""
    {prompt_template}

    RTL files:
    ```systemverilog
    {rtl_text[:30000]}
    Generate a markdown RTL review.
    Focus on real ASIC/FPGA RTL quality issues:
    - combinational vs sequential logic
    - reset behavior
    - synthesis risks
    - inferred latches
    - undriven signals
    - memory addressing
    - RISC-V decode correctness
    - useful assertions
    Do not invent modules or signals. If a signal name is uncertian say so.
    """
    report = run_codex(prompt, fallback)
    write_text(OUT_REPORT, report)
    print(f"Generated {OUT_REPORT}")
if __name__ == "__main__":
    main()

