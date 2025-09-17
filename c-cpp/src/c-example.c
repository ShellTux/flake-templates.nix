#include "example.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *strdup(const char *source) {
  return strcpy(malloc(strlen(source) + 1), source);
}

int main(void) {
  {
    const char *string = "Hello world from c!";
    char *dupStr = strdup(string);

    printf("string = %s\n", string);
    printf("dupStr = %s\n", dupStr);

    // Memory leak
  }

  {
    const size_t n = 6;

    printf("%zu! = %zu\n", n, factorial(n));
  }

  return 0;
}
