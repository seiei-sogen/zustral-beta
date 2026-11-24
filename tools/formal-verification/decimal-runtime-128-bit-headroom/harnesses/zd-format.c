#include "decimal-runtime-under-check.h"

/* zd_format(x, s, buf): zd_to_double and au_dec_debug_print pass a 48-byte buffer. */
int main(void) {
  int s = nondet_scale_up_to(38);
  au_decimal_t x = nondet_coefficient(38);
  char buf[48];
  int length = zd_format(x, s, buf);
  __CPROVER_assert(0 < length && length < 48, "zd_format writes the text and its terminator inside the buffer");
  return 0;
}
