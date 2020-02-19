// freely inspired from https://github.com/gcc-mirror/gcc/tree/master/libiberty

void* fame_memcpy(void* v_dst, void* v_src, unsigned int len) {
  unsigned char* c_dst = v_dst;
  unsigned char* c_src = v_src;
  while (len--) *c_dst++ = *c_src++;
  return v_dst;
}

int fame_memcmp(void* v1, void* v2, unsigned int len) {
  unsigned char* c1 = v1;
  unsigned char* c2 = v2;
  while (len-- > 0)
    if (*c1++ != *c2++)
      return c1[-1] < c2[-1] ? -1 : 1;
  return 0;
}
