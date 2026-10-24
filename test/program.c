// What the build is for, in one file: freestanding rv32 C with the two calls clang makes
// on its own -- memset for a zeroed aggregate -- answered here, linked by lld.
typedef unsigned int size_t;

void *memset(void *destination, int value, size_t count) {
  unsigned char *to = destination;

  while (count-- > 0) {
    *to++ = (unsigned char)value;
  }
  return destination;
}

struct pair {
  int words[10];
};

int consume(struct pair *pair);

void _start(void) {
  struct pair pair = {0};

  for (;;) {
    consume(&pair);
  }
}

int consume(struct pair *pair) { return pair->words[0]; }
