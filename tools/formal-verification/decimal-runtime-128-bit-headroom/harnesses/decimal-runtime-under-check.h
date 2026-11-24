/* Shared by every CBMC harness in this directory. It compiles the Decimal runtime
   (decimal.h, decimal.c from the directory the check script puts first on the
   include path) and gives the harnesses a 256-bit integer to state exact values in.
   See ../../../../.claude/skills/verify-decimal-runtime-128-bit-headroom/SKILL.md. */

/* A trap in the runtime ends the program, so no path continues past it. */
unsigned char au_abort_internal(const char *message) {
  __CPROVER_assume(0);
  return 0;
}

static void zd_write_line(const char *text) {}

#include "decimal.h"
#include "decimal.c"

int nondet_int(void);
__int128 nondet_int128(void);
unsigned long long nondet_unsigned_long_long(void);

/* Wide enough for every exact value below: 10^38 * 10^38 < 2^253. */
typedef signed __CPROVER_bitvector[256] exact_integer;

static exact_integer exact_power_of_ten(int n) {
  exact_integer power = 1;
  for (int i = 0; i < n; i++) power = power * 10;
  return power;
}

/* |coefficient| < 10^precision, computed without the runtime's own helpers. */
static int exact_coefficient_fits(exact_integer coefficient, int precision) {
  exact_integer limit = exact_power_of_ten(precision);
  return -limit < coefficient && coefficient < limit;
}

static int nondet_precision(void) {
  int precision = nondet_int();
  __CPROVER_assume(1 <= precision && precision <= 38);
  return precision;
}

static int nondet_scale_up_to(int precision) {
  int scale = nondet_int();
  __CPROVER_assume(0 <= scale && scale <= precision);
  return scale;
}

static zd_mode nondet_rounding_mode(void) {
  int mode = nondet_int();
  __CPROVER_assume(ZD_NEAREST_EVEN <= mode && mode <= ZD_TOWARD_LESSER);
  return (zd_mode)mode;
}

/* A coefficient of Decimal[precision, S], for any S. */
static au_decimal_t nondet_coefficient(int precision) {
  au_decimal_t coefficient = nondet_int128();
  __CPROVER_assume(exact_coefficient_fits(coefficient, precision));
  return coefficient;
}
