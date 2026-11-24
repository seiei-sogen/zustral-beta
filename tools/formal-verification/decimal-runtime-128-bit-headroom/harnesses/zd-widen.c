#include "decimal-runtime-under-check.h"

/* zd_widen(x, s, s2): the compiler guarantees s2 >= s and that the result fits
   Decimal[38, s2]. */
int main(void) {
  int s2 = nondet_scale_up_to(38), s = nondet_scale_up_to(s2);
  au_decimal_t x = nondet_coefficient(38);
  __CPROVER_assume(exact_coefficient_fits((exact_integer)x * exact_power_of_ten(s2 - s), 38));
  zd_widen(x, s, s2);
  return 0;
}
