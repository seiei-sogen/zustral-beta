#include "decimal-runtime-under-check.h"

/* zd_sub(a, b, p): both operands are Decimal[P, S]. */
int main(void) {
  int p = nondet_precision();
  au_decimal_t a = nondet_coefficient(p), b = nondet_coefficient(p), out;
  int succeeded = zd_sub(a, b, p, &out);
  exact_integer difference = (exact_integer)a - (exact_integer)b;
  __CPROVER_assert(succeeded == exact_coefficient_fits(difference, p), "zd_sub fails exactly when the difference does not fit the precision");
  if (succeeded) __CPROVER_assert((exact_integer)out == difference, "zd_sub returns the exact difference");
  return 0;
}
