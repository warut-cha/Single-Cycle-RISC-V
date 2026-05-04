import subprocess
from pathlib import Path


AGENTS = [
    "tools.ai_agent.triage_agent",
    "tools.ai_agent.rtl_reviewer_agent",
    "tools.ai_agent.tb_agent",
]


def main():
    Path("reports/ai").mkdir(parents=True, exist_ok=True)

    for agent in AGENTS:
        print(f"\nRunning {agent}")
        subprocess.run(["python3", "-m", agent], check=True)

    print("\nGenerated AI agent reports:")
    for report in sorted(Path("reports/ai").glob("*.md")):
        print(f"- {report}")


if __name__ == "__main__":
    main()