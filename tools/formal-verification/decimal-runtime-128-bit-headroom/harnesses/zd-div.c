#include "decimal-runtime-under-check.h"

/* zd_div(a, s1, b, s2, p3, s3, mode): a is Decimal[P1, S1], b is Decimal[P2, S2],
   the result is Decimal[P3, S3]. P1 = P2 = 38 admits every coefficient of every
   precision, and every scale. The check script replaces the long-division loop by
   its invariant (inject-long-division-loop-invariant.py), so every k = s2 + s3 - s1
   from -38 to 76 is covered in one run. */
int main(void) {
  int s1 = nondet_scale_up_to(38), s2 = nondet_scale_up_to(38);
  int p3 = nondet_precision(), s3 = nondet_scale_up_to(p3);
  zd_mode mode = nondet_rounding_mode();
  au_decimal_t a = nondet_coefficient(38), b = nondet_coefficient(38), out;
  int succeeded = zd_div(a, s1, b, s2, p3, s3, mode, &out);
  if (b == 0) __CPROVER_assert(!succeeded, "zd_div fails on a zero divisor");
  if (succeeded) __CPROVER_assert(exact_coefficient_fits(out, p3), "a zd_div result fits the result precision");
  return 0;
}
