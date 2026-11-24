#include "decimal-runtime-under-check.h"

/* zd_add(a, b, p): both operands are Decimal[P, S]. */
int main(void) {
  int p = nondet_precision();
  au_decimal_t a = nondet_coefficient(p), b = nondet_coefficient(p), out;
  int succeeded = zd_add(a, b, p, &out);
  exact_integer sum = (exact_integer)a + (exact_integer)b;
  __CPROVER_assert(succeeded == exact_coefficient_fits(sum, p), "zd_add fails exactly when the sum does not fit the precision");
  if (succeeded) __CPROVER_assert((exact_integer)out == sum, "zd_add returns the exact sum");
  return 0;
}
