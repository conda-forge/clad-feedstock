#include "clad/Differentiator/Differentiator.h"

double sq (double x) { return x*x; }

int main() {
  auto d_sq = clad::differentiate(sq, "x");
  return d_sq.execute(1) != 2; // success
}
