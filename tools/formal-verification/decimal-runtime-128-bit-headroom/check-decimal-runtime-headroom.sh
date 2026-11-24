#!/usr/bin/env bash
# Checks with CBMC, for every input the compiler can pass, that the Decimal runtime
# never wraps a 128-bit or 64-bit intermediate, never runs into C undefined behaviour,
# and returns only coefficients that fit the result precision. What it covers and how
# to read a failure: .claude/skills/verify-decimal-runtime-128-bit-headroom/SKILL.md.
#
# CBMC comes from shell.nix, so run it inside nix-shell:
#   nix-shell --command 'tools/formal-verification/decimal-runtime-128-bit-headroom/check-decimal-runtime-headroom.sh'
# Options:
#   --runtime <dir>  the directory that holds decimal.h and decimal.c
#                    (default: docs/research/decimal-prototype/runtime)
#   --mutants        also break the runtime on purpose, once per mutant below, and
#                    require the check to fail on each of them
#   --keep           keep the CBMC logs and print where they are
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
runtime=$ROOT/docs/research/decimal-prototype/runtime
run_mutants=0 keep=0
while (($#)); do
  case $1 in
    --runtime) runtime=$(cd "$2" && pwd); shift 2 ;;
    --mutants) run_mutants=1; shift ;;
    --keep) keep=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
for tool in cbmc goto-cc goto-instrument python3; do
  command -v "$tool" > /dev/null || { echo "$tool is not on PATH; run this inside nix-shell" >&2; exit 2; }
done

HARNESSES=(zd-add zd-sub zd-mul zd-div zd-round zd-exact zd-widen zd-from-double au-dec-lit zd-format)
CHECKS=(--bounds-check --pointer-check --div-by-zero-check --signed-overflow-check
        --unsigned-overflow-check --undefined-shift-check)

work=$(mktemp -d)
if ((keep)); then echo "logs: $work"; else trap 'rm -rf "$work"' EXIT; fi

# prepare_runtime <dir> <decimal.c>: decimal.h, and decimal.c with the loop invariants.
prepare_runtime() {
  mkdir -p "$1"
  cp "$runtime/decimal.h" "$1/"
  python3 "$HERE/inject-long-division-loop-invariant.py" "$2" > "$1/decimal.c"
}

# verify_harness <runtime dir> <harness> <log prefix>: 0 when CBMC proves every property.
# zd_pow10 is unrolled before the invariants are applied, because zd_div calls it
# inside its digit loop.
verify_harness() {
  {
    goto-cc -I "$1" "$HERE/harnesses/$2.c" -o "$3.source.gb" &&
      goto-instrument --unwindset zd_pow10.0:40 --unwinding-assertions "$3.source.gb" "$3.unrolled.gb" &&
      goto-instrument --apply-loop-contracts "$3.unrolled.gb" "$3.gb" &&
      cbmc "$3.gb" --unwind 41 --unwindset zd_from_double.0:257 --unwinding-assertions "${CHECKS[@]}"
  } > "$3.log" 2>&1 && grep -q '^VERIFICATION SUCCESSFUL$' "$3.log"
}

# The failed properties of a log, one per line, with the line of decimal.c they guard.
failed_properties() {
  grep -E '^\[.*\] .*FAILURE$' "$1" | sed 's/^/    /'
}

prepare_runtime "$work/runtime" "$runtime/decimal.c" || exit 1
echo "== CBMC on $runtime"
for harness in "${HARNESSES[@]}"; do
  ( start=$SECONDS
    if verify_harness "$work/runtime" "$harness" "$work/$harness"; then status=verified; else status=FAILED; fi
    echo "$status $harness $((SECONDS - start))s" > "$work/$harness.status" ) &
  while (($(jobs -rp | wc -l) >= $(nproc))); do wait -n; done
done
wait

failed=0
for harness in "${HARNESSES[@]}"; do
  cat "$work/$harness.status"
  if grep -q '^FAILED' "$work/$harness.status"; then
    failed=$((failed + 1))
    failed_properties "$work/$harness.log"
    # No failed property: CBMC or a step before it stopped. Show how it ended.
    grep -qE 'FAILURE$' "$work/$harness.log" || tail -n 5 "$work/$harness.log" | sed 's/^/    /'
  fi
done


# mutant <name> <harness> <fragment> <replacement>: replaces one fragment of
# decimal.c, and the named harness must then fail.
caught=0 missed=0
mutant() {
  local dir=$work/mutant-$1
  mkdir -p "$dir"
  if ! python3 - "$runtime/decimal.c" "$3" "$4" > "$dir/decimal.c" <<'PY'
import sys
source, old, new = open(sys.argv[1]).read(), sys.argv[2], sys.argv[3]
sys.exit(1) if source.count(old) != 1 else sys.stdout.write(source.replace(old, new))
PY
  then
    echo "mutant $1: fragment not found exactly once in decimal.c"; missed=$((missed + 1)); return
  fi
  if prepare_runtime "$dir/runtime" "$dir/decimal.c" && verify_harness "$dir/runtime" "$2" "$dir/$2"; then
    echo "mutant $1: NOT detected by $2"; missed=$((missed + 1))
  else
    echo "mutant $1: detected by $2"; caught=$((caught + 1))
    failed_properties "$dir/$2.log" | head -3
  fi
}

if ((run_mutants)); then
  echo "== mutants: each must make its harness fail"
  mutant div-times-ten-wraps zd-div '      for (int j = 0; j < 10; j++) {
        acc += r;
        if (acc >= nb) { acc -= nb; digit++; }
      }' '      acc = r * 10; digit = (unsigned)(acc / nb); acc = acc % nb;'
  mutant div-no-early-overflow-exit zd-div '      if (q >= zd_pow10(37)) return 0;
' ''
  mutant add-skips-precision-check zd-add '  if (__builtin_add_overflow(a, b, &r)) return 0;
  if (zd_abs(r) >= zd_pow10(p)) return 0;' '  if (__builtin_add_overflow(a, b, &r)) return 0;'
  mutant sub-wraps zd-sub '  if (__builtin_sub_overflow(a, b, &r)) return 0;' '  r = a - b;'
  mutant mul-scales-the-product zd-mul '  return a * b;' '  return a * b * 10;'
  mutant round-skips-digit-count-guard zd-round '    if (n != 0 && (up > p2 || n >= zd_pow10(p2 - up))) return 0;
' ''
  mutant exact-skips-digit-count-guard zd-exact '    if (n != 0 && (up > p2 || n >= zd_pow10(p2 - up))) return 0;
' ''
  mutant widen-one-digit-too-many zd-widen 'zd_pow10(s2 - s)' 'zd_pow10(s2 - s + 1)'
  mutant from-double-shifts-past-128-bits zd-from-double '    if (exponent > 74) return 0;
' ''
  mutant literal-high-part-wraps-in-64-bits au-dec-lit '(zd_u128)hi * 10000000000000000000ULL' '(zd_u128)(hi * 10000000000000000000ULL)'
  mutant format-digit-buffer-too-short zd-format '  char digits[40];' '  char digits[38];'
  echo "mutants detected $caught / not detected $missed"
  failed=$((failed + missed))
fi

((failed == 0)) && echo "all checks as expected"
((failed == 0))
