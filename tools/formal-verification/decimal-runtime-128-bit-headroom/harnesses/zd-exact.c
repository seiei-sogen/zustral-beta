#include "decimal-runtime-under-check.h"

/* zd_exact(x, s, p2, s2): as zd_round, without a rounding mode. */
int main(void) {
  int s = nondet_scale_up_to(38), p2 = nondet_precision(), s2 = nondet_scale_up_to(p2);
  au_decimal_t x = nondet_coefficient(38), out;
  if (zd_exact(x, s, p2, s2, &out))
    __CPROVER_assert(exact_coefficient_fits(out, p2), "a zd_exact result fits the result precision");
  return 0;
}
