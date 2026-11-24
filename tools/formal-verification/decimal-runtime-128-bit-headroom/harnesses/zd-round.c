#include "decimal-runtime-under-check.h"

/* zd_round(x, s, p2, s2, mode): x is Decimal[P, S], the result is Decimal[P2, S2].
   P = 38 admits every coefficient of every precision. */
int main(void) {
  int s = nondet_scale_up_to(38), p2 = nondet_precision(), s2 = nondet_scale_up_to(p2);
  zd_mode mode = nondet_rounding_mode();
  au_decimal_t x = nondet_coefficient(38), out;
  if (zd_round(x, s, p2, s2, mode, &out))
    __CPROVER_assert(exact_coefficient_fits(out, p2), "a zd_round result fits the result precision");
  return 0;
}
