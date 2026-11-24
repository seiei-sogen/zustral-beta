"""Writes decimal.c with CBMC loop invariants on the two long-division loops of zd_div.

    inject-long-division-loop-invariant.py <decimal.c> > <copy of decimal.c>

The invariants are annotations: they do not change what the code computes.
Each goes on a line of its own: on the loop's header line, CBMC 5.76's loop
contracts fail to find the end of zd_format's do-while loop. So lines after
the digit loop's header are 2 lines (4 after the inner loop's) below their
line in decimal.c. CBMC
checks that each holds on entry and after one arbitrary iteration, so the check
covers every number of digits k, not just the ones it could unroll. The digit
loop must be found exactly once: if it is not, zd_div has changed, and the
invariant has to be written again for the new loop (see the skill). The inner
loop is annotated where it is found. Where it is gone, the digit loop needs no
inner invariant, and if its header changed, CBMC stops because an inner loop of
an annotated loop has no invariant.
"""
import sys

TEN_TO_THE_38 = "((zd_u128)10000000000000000000ULL * 10000000000000000000ULL)"

DIGIT_LOOP, INNER_LOOP = [
    # The digit loop: q stays below 10^38 because each step runs only when q < 10^37.
    ("    for (int i = 0; i < k; i++) {\n",
     "    for (int i = 0; i < k; i++)\n"
     f"      __CPROVER_loop_invariant(0 <= i && i <= k && r < nb && q < {TEN_TO_THE_38})\n"
     "    {\n"),
    # Adding r ten times: the running sum stays below the divisor after each step,
    # and since r < nb, fewer than j of the j additions can reach the divisor, so the
    # digit ends below 10.
    ("      for (int j = 0; j < 10; j++) {\n",
     "      for (int j = 0; j < 10; j++)\n"
     "        __CPROVER_loop_invariant((j == 0 && acc == 0 && digit == 0)"
     " || (1 <= j && j <= 10 && acc < nb && digit < (unsigned)j))\n"
     "      {\n"),
]


def main() -> int:
    source = open(sys.argv[1]).read()
    header, annotated = DIGIT_LOOP
    if source.count(header) != 1:
        sys.stderr.write(f"the long-division digit loop is not found exactly once in {sys.argv[1]}: {header!r}\n")
        return 1
    source = source.replace(header, annotated)
    header, annotated = INNER_LOOP
    if source.count(header) == 1:
        source = source.replace(header, annotated)
    sys.stdout.write(source)
    return 0


if __name__ == "__main__":
    sys.exit(main())
