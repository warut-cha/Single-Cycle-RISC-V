from pathlib import Path
import re

from tools.common.file_utils import read_text, read_glob, write_text
from tools.common.codex_client import run_codex, load_prompt_template


OUT_REPORT = "reports/ai/verification_gap_report.md"
GENERATED_TEST_DIR = Path("tb/generated")


INSTRUCTION_TESTS = {
    "add": {
        "goal": "Verify ADD register-register operation.",
        "asm": [
            "addi x1, x0, 5",
            "addi x2, x0, 10",
            "add x3, x1, x2",
        ],
        "expected": [
            "x1 = 5",
            "x2 = 10",
            "x3 = 15",
        ],
    },

    "sub": {
        "goal": "Verify SUB register-register operation.",
        "asm": [
            "addi x1, x0, 10",
            "addi x2, x0, 5",
            "sub x3, x1, x2",
        ],
        "expected": [
            "x1 = 10",
            "x2 = 5",
            "x3 = 5",
        ],
    },

    "and": {
        "goal": "Verify bitwise AND operation.",
        "asm": [
            "addi x1, x0, 15      # 0b1111",
            "addi x2, x0, 10      # 0b1010",
            "and x3, x1, x2       # expected 0b1010",
        ],
        "expected": [
            "x3 = 10",
        ],
    },

    "or": {
        "goal": "Verify bitwise OR operation.",
        "asm": [
            "addi x1, x0, 12      # 0b1100",
            "addi x2, x0, 10      # 0b1010",
            "or x3, x1, x2        # expected 0b1110",
        ],
        "expected": [
            "x3 = 14",
        ],
    },

    "xor": {
        "goal": "Verify bitwise XOR operation.",
        "asm": [
            "addi x1, x0, 12      # 0b1100",
            "addi x2, x0, 10      # 0b1010",
            "xor x3, x1, x2       # expected 0b0110",
        ],
        "expected": [
            "x3 = 6",
        ],
    },

    "mul": {
        "goal": "Verify MUL operation.",
        "asm": [
            "addi x1, x0, 5",
            "addi x2, x0, 10",
            "mul x3, x1, x2",
        ],
        "expected": [
            "x3 = 50",
        ],
    },

    "slt_true": {
        "goal": "Verify SLT when rs1 < rs2.",
        "asm": [
            "addi x1, x0, 5",
            "addi x2, x0, 10",
            "slt x3, x1, x2",
        ],
        "expected": [
            "x3 = 1",
        ],
    },

    "slt_false": {
        "goal": "Verify SLT when rs1 >= rs2.",
        "asm": [
            "addi x1, x0, 10",
            "addi x2, x0, 5",
            "slt x3, x1, x2",
        ],
        "expected": [
            "x3 = 0",
        ],
    },

    "slt_signed": {
        "goal": "Verify signed SLT behavior with a negative operand.",
        "asm": [
            "addi x1, x0, -1",
            "addi x2, x0, 1",
            "slt x3, x1, x2",
        ],
        "expected": [
            "x3 = 1",
        ],
    },

    "addi_positive": {
        "goal": "Verify ADDI with positive immediate.",
        "asm": [
            "addi x1, x0, 42",
        ],
        "expected": [
            "x1 = 42",
        ],
    },

    "addi_negative": {
        "goal": "Verify ADDI with sign-extended negative immediate.",
        "asm": [
            "addi x1, x0, -1",
        ],
        "expected": [
            "x1 = 0xffffffff",
        ],
    },

    "lw_sw": {
        "goal": "Verify SW followed by LW.",
        "asm": [
            "addi x1, x0, 100",
            "addi x2, x0, 42",
            "sw x2, 0(x1)",
            "lw x3, 0(x1)",
        ],
        "expected": [
            "x3 = 42",
        ],
    },

    "x0_write_protection": {
        "goal": "Verify attempted write to x0 is ignored.",
        "asm": [
            "addi x0, x0, 123",
            "addi x1, x0, 5",
        ],
        "expected": [
            "x0 = 0",
            "x1 = 5",
        ],
    },
}


def detect_instruction_mentions(text: str):
    found = set()
    for instr in INSTRUCTION_TESTS:
        if re.search(rf"\b{re.escape(instr)}\b", text, flags=re.IGNORECASE):
            found.add(instr)
    return found


def build_rule_based_report(rtl_text: str, tb_text: str, sim_log: str, verification_plan: str) -> str:
    combined = "\n".join([tb_text, sim_log, verification_plan])
    tested = detect_instruction_mentions(combined)

    report = []
    report.append("# Verification Gap Report\n")

    report.append("## Detected Test Coverage From Existing Files\n")
    if tested:
        for instr in sorted(tested):
            report.append(f"- `{instr}` appears to be covered or mentioned.")
    else:
        report.append("- No instruction coverage detected from simple text scan.")

    report.append("\n## Suggested Directed Tests\n")

    for instr, info in INSTRUCTION_TESTS.items():
        if instr not in tested:
            report.append(f"### Missing or weak coverage: `{instr}`")
        else:
            report.append(f"### Strengthen coverage: `{instr}`")

        report.append(f"- Goal: {info['goal']}")
        report.append("- Program:")
        report.append("```asm")
        report.extend(info["asm"])
        report.append("```")
        report.append("- Expected:")
        for exp in info["expected"]:
            report.append(f"  - `{exp}`")
        report.append("")

    report.append("## Recommended Testbench Improvements\n")
    report.append("- Replace final print-only checks with strict `if (...) $fatal;` checks.")
    report.append("- Use `!==` instead of `!=` to catch X/Z values.")
    report.append("- Add separate tests for ADD, SUB, AND, OR, XOR, MUL, SLT, ADDI, LW, SW, reset, and x0 behavior.")
    report.append("- Add separate tests for ALU operations, memory operations, reset behavior, and x0 write protection.")
    report.append("- Add a helper task like `check_reg(reg_id, expected_value)`.")
    report.append("- Add VCD waveform dumping only when debugging or when CI fails.")

    return "\n".join(report)


def write_sample_asm_tests():
    GENERATED_TEST_DIR.mkdir(parents=True, exist_ok=True)

    for instr, info in INSTRUCTION_TESTS.items():
        path = GENERATED_TEST_DIR / f"{instr}_test.s"
        content = []
        content.append(f"# Auto-suggested directed test for {instr}")
        content.append(f"# Goal: {info['goal']}")
        content.append("")
        content.extend(info["asm"])
        content.append("")
        content.append("# Expected:")
        for exp in info["expected"]:
            content.append(f"# {exp}")
        path.write_text("\n".join(content))


def main():
    rtl_text = read_glob("src/rtl/*.sv", max_chars_per_file=8000)
    tb_text = read_glob("tb/*.sv", max_chars_per_file=12000)
    sim_log = read_text("reports/sim/sim_log.txt")
    verification_plan = read_text("docs/verification_plan.md")

    fallback = build_rule_based_report(rtl_text, tb_text, sim_log, verification_plan)
    write_sample_asm_tests()

    prompt_template = load_prompt_template("tools/rtl_agents/prompts/tb_generator.md")

    prompt = f"""
    {prompt_template}

    RTL summary/files:
    ```systemverilog
    {rtl_text[:20000]}
    Current testbench:
    {tb_text[:16000]}
    Simulation log:
    {sim_log[-4000:]}
    Verification plan:
    {verification_plan[:8000]}
    Generate a markdown verificaiton gap report.
    Suggest directed tests, assertions, and testbench improvements.
    Do not cliam a test exists unless it is visible in the input.
    """
    report = run_codex(prompt,fallback)
    write_text(OUT_REPORT,report)
    print(f"Generated {OUT_REPORT}")
    print(f"Generated sample tests in {GENERATED_TEST_DIR}")

if __name__ == "__main__":
    main()