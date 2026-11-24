#include "decimal-runtime-under-check.h"

/* zd_mul(a, b): a is Decimal[P1, S1], b is Decimal[P2, S2], and the compiler
   guarantees P1 + P2 <= 38. The overflow checks cover the product. */
int main(void) {
  int p1 = nondet_precision(), p2 = nondet_precision();
  __CPROVER_assume(p1 + p2 <= 38);
  au_decimal_t a = nondet_coefficient(p1), b = nondet_coefficient(p2);
  zd_mul(a, b);
  return 0;
}
