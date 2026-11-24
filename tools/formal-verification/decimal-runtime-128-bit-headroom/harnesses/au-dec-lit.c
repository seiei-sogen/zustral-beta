#include "decimal-runtime-under-check.h"

/* au_dec_lit(negative, hi, lo): the compiler splits a coefficient below 10^38 as
   hi * 10^19 + lo with lo < 10^19, so hi < 10^19 too. Comparing the result with
   hi * 10^19 + lo would make CBMC prove two multipliers equal, which runs for
   more than 25 minutes; the overflow checks cover the multiplication instead. */
int main(void) {
  int negative = nondet_int();
  __CPROVER_assume(negative == 0 || negative == 1);
  unsigned long long hi = nondet_unsigned_long_long(), lo = nondet_unsigned_long_long();
  __CPROVER_assume(hi < 10000000000000000000ULL && lo < 10000000000000000000ULL);
  au_decimal_t coefficient = au_dec_lit(negative, hi, lo);
  __CPROVER_assert(exact_coefficient_fits(coefficient, 38), "au_dec_lit returns a coefficient below 10^38");
  __CPROVER_assert(negative ? coefficient <= 0 : coefficient >= 0, "au_dec_lit keeps the sign the compiler gave");
  return 0;
}
