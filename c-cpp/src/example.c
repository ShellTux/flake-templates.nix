#include "example.h"

size_t factorial(const size_t number) {
  if (number <= 1) {
    return 1;
  }

  return number * factorial(number - 1);
}
