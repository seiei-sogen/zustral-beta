#include "decimal-runtime-under-check.h"

/* au_dec_lit(negative, hi, lo): the compiler splits a coefficient below 10^38 as
   hi * 10^19 + lo with lo < 10^19. */
int main(void) {
  int negative = nondet_int();
  __CPROVER_assume(negative == 0 || negative == 1);
  unsigned long long hi = nondet_unsigned_long_long(), lo = nondet_unsigned_long_long();
  exact_integer magnitude = (exact_integer)hi * exact_power_of_ten(19) + (exact_integer)lo;
  __CPROVER_assume(lo < 10000000000000000000ULL && exact_coefficient_fits(magnitude, 38));
  au_decimal_t coefficient = au_dec_lit(negative, hi, lo);
  __CPROVER_assert((exact_integer)coefficient == (negative ? -magnitude : magnitude), "au_dec_lit returns the coefficient the compiler split");
  return 0;
}
