#include "decimal-runtime-under-check.h"

/* zd_from_double(f, p2, s2, mode): every Float64 bit pattern, NaN and infinity included. */
int main(void) {
  union { double f; unsigned long long bits; } value;
  value.bits = nondet_unsigned_long_long();
  int p2 = nondet_precision(), s2 = nondet_scale_up_to(p2);
  zd_mode mode = nondet_rounding_mode();
  au_decimal_t out;
  if (zd_from_double(value.f, p2, s2, mode, &out))
    __CPROVER_assert(exact_coefficient_fits(out, p2), "a zd_from_double result fits the result precision");
  return 0;
}
