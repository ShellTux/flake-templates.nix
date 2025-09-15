#include "example.h"
#include <stddef.h>
#include <stdio.h>

int main(void) {
  const size_t n = 6;

  printf("Hello world from c!\n");
  printf("%zu! = %zu\n", n, factorial(n));

  return 0;
}
