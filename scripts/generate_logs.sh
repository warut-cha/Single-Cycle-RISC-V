set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p build
mkdir -p reports/sim
mkdir -p reports/lint
mkdir -p reports/synth
mkdir -p reports/ai

echo "Generating sim_log"
echo
iverilog -o build/top_sim \
  src/rtl/pc.sv \
  src/rtl/imem.sv \
  src/rtl/decoder.sv \
  src/rtl/regfile.sv \
  src/rtl/alu.sv \
  src/rtl/dmem.sv \
  src/rtl/apb_led.sv \
  src/rtl/top.sv \
  tb/top_tb.sv \
  2>&1 | tee reports/sim/compile_log.txt

if [ -f build/top_sim ]; then
  vvp build/top_sim 2>&1 | tee reports/sim/sim_log.txt
else
  echo "Simulation compile failed. build/top_sim was not created." | tee reports/sim/sim_log.txt
fi

echo
echo "Generating synth_log"
echo

if [ -f scripts/synth.ys ]; then
  yosys -s scripts/synth.ys \
    2>&1 | tee reports/synth/synth_log.txt
else
  echo "Missing scripts/synth.ys" | tee reports/synth/synth_log.txt
fi


echo 
echo "Genrating lint_log"
echo

{
  echo "Running Verilator lint..."
  verilator --lint-only --Wall --top-module top \
    src/rtl/pc.sv \
    src/rtl/imem.sv \
    src/rtl/decoder.sv \
    src/rtl/regfile.sv \
    src/rtl/alu.sv \
    src/rtl/dmem.sv \
    src/rtl/apb_led.sv \
    src/rtl/top.sv
  status=$?
  echo "Verilator exit code: $status"

  if [ "$status" -eq 0 ]; then
    echo "LINT PASS"
  else
    echo "LINT FAIL"
  fi

  exit "$status"
} 2>&1 | tee reports/lint/lint_log.txt

echo
echo "Generated logs"
echo 
echo "Simulation log: reports/sim/sim_log.txt"
echo "Compile log:    reports/sim/compile_log.txt"
echo "Lint log:       reports/lint/lint_log.txt"
echo "Synthesis log:  reports/synth/synth_log.txt"