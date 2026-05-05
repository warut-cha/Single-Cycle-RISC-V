import os
import subprocess
from pathlib import Path


AGENTS = [
    "tools.ai_agent.triage_agent",
    "tools.ai_agent.rtl_reviewer_agent",
    "tools.ai_agent.tb_agent",
]


def run_command(cmd, log_path=None, check=False):
    """
    Run a shell command and optionally save combined stdout/stderr to a log file.
    """
    print(f"\nRunning command: {' '.join(cmd)}")

    result = subprocess.run(
        cmd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )

    print(result.stdout)

    if log_path is not None:
        Path(log_path).parent.mkdir(parents=True, exist_ok=True)
        Path(log_path).write_text(result.stdout)

    if check and result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd)

    return result.returncode


def run_regression(label):
    """
    Run the full RTL regression flow and save a copy of the output.
    """
    log_path = f"reports/ai/{label}_regression.log"

    status = run_command(
        ["bash", "scripts/generate_logs.sh"],
        log_path=log_path,
        check=False,
    )

    if status == 0:
        print(f"\n{label} regression PASS")
    else:
        print(f"\n{label} regression FAIL")

    return status


def run_agents():
    """
    Run all configured AI agents.
    """
    Path("reports/ai").mkdir(parents=True, exist_ok=True)

    for agent in AGENTS:
        print(f"\nRunning {agent}")
        status = run_command(["python3", "-m", agent], check=False)

        if status != 0:
            print(f"WARNING: {agent} exited with status {status}")


def show_reports():
    print("\nGenerated AI agent reports:")
    for report in sorted(Path("reports/ai").glob("*.md")):
        print(f"- {report}")


def main():
    Path("reports/ai").mkdir(parents=True, exist_ok=True)

    auto_repair = os.getenv("AUTO_REPAIR", "0") == "1"

    if not auto_repair:
        print("AUTO_REPAIR=0: running AI agents in analyze/report-only mode.")
        run_agents()
        show_reports()
        return

    print("AUTO_REPAIR=1: running AI agents in repair mode.")

    before_status = run_regression("before_repair")

    if before_status == 0:
        print("\nRegression already passes. No RTL repair needed.")
        run_agents()
        show_reports()
        return

    print("\nRegression failed. Running AI agents with repair tools enabled.")
    run_agents()

    print("\nRerunning regression after AI repair attempt.")
    after_status = run_regression("after_repair")

    show_reports()

    if after_status == 0:
        print("\nAI repair succeeded. Regression now passes.")
        return

    print("\nAI repair did not fix all failures. Regression still fails.")
    raise SystemExit(1)


if __name__ == "__main__":
    main()