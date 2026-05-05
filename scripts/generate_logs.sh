set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p build
mkdir -p reports/sim
mkdir -p reports/riscv_tests
mkdir -p reports/lint
mkdir -p reports/synth
mkdir -p reports/ai

echo 
echo "Generating sim_log"
echo

iverilog -g2012 -o build/top_sim \
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

compile_status=${PIPESTATUS[0]}

if [ "$compile_status" -ne 0 ]; then
  echo "Simulation compile failed. build/top_sim was not created." | tee reports/sim/sim_log.txt
else
  echo
  echo "Running default APB/control-flow simulation"
  vvp build/top_sim 2>&1 | tee reports/sim/sim_log.txt

  default_sim_status=${PIPESTATUS[0]}

  echo
  echo "Running selected riscv-tests"
  echo

  riscv_status=0

TEST_DIR="tests/riscv_comp"

if compgen -G "$TEST_DIR/*.hex" > /dev/null; then
  for hex_file in "$TEST_DIR"/*.hex; do
    test_name="$(basename "$hex_file" .hex)"
    log_file="reports/riscv_tests/${test_name}.log"

    case "$test_name" in
      addi)
        test_id=1
        ;;
      add_sub)
        test_id=2
        ;;
      logic)
        test_id=3
        ;;
      slt)
        test_id=4
        ;;
      load_store)
        test_id=5
        ;;
      branch_jump)
        test_id=6
        ;;
      mul)
        test_id=7
        ;;
      *)
        echo "Unknown test name: $test_name"
        riscv_status=1
        continue
        ;;
    esac

    echo
    echo "Running $test_name"
    echo "Program: $hex_file"
    echo "TEST_ID: $test_id"

    vvp build/top_sim +PROGRAM="$hex_file" +TEST_ID="$test_id" \
      2>&1 | tee "$log_file"

    test_status=${PIPESTATUS[0]}

    if [ "$test_status" -eq 0 ]; then
      echo "PASS: $test_name"
    else
      echo "FAIL: $test_name"
      riscv_status=1
    fi
  done
else
  echo "No tests found in $TEST_DIR/*.hex"
fi
fi

echo
echo "Generating synth_log"
echo 

if [ -f scripts/synth.ys ]; then
  yosys -s scripts/synth.ys \
    2>&1 | tee reports/synth/synth_log.txt
  synth_status=${PIPESTATUS[0]}
else
  echo "Missing scripts/synth.ys" | tee reports/synth/synth_log.txt
  synth_status=1
fi

echo
echo "Generating lint_log"
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

  lint_status=$?
  echo "Verilator exit code: $lint_status"

  if [ "$lint_status" -eq 0 ]; then
    echo "LINT PASS"
  else
    echo "LINT FAIL"
  fi

  exit "$lint_status"
} 2>&1 | tee reports/lint/lint_log.txt

lint_status=${PIPESTATUS[0]}

echo
echo "Generated logs"
echo 
echo "Simulation log:       reports/sim/sim_log.txt"
echo "Compile log:          reports/sim/compile_log.txt"
echo "RISC-V test logs:     reports/riscv_tests/"
echo "Lint log:             reports/lint/lint_log.txt"
echo "Synthesis log:        reports/synth/synth_log.txt"

echo
echo "Final status"
echo 

final_status=0

if [ "${compile_status:-1}" -ne 0 ]; then
  echo "COMPILE FAIL"
  final_status=1
else
  echo "COMPILE PASS"
fi

if [ "${default_sim_status:-1}" -ne 0 ]; then
  echo "DEFAULT SIM FAIL"
  final_status=1
else
  echo "DEFAULT SIM PASS"
fi

if [ "${riscv_status:-0}" -ne 0 ]; then
  echo "RISCV TESTS FAIL"
  final_status=1
else
  echo "RISCV TESTS PASS"
fi

if [ "${synth_status:-1}" -ne 0 ]; then
  echo "SYNTH FAIL"
  final_status=1
else
  echo "SYNTH PASS"
fi

if [ "${lint_status:-1}" -ne 0 ]; then
  echo "LINT FAIL"
  final_status=1
else
  echo "LINT PASS"
fi

exit "$final_status"