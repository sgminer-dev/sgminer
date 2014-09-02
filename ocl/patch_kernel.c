#include "patch_kernel.h"
#include "logging.h"
#include <string.h>
#include <stdint.h>

static int advance(char **area, unsigned *remaining, const char *marker)
{
  char *find = (char *)memmem(*area, *remaining, (void *)marker, strlen(marker));

  if (!find) {
    applog(LOG_DEBUG, "Marker \"%s\" not found", marker);
    return 0;
  }
  *remaining -= find - *area;
  *area = find;
  return 1;
}

#define OP3_INST_BFE_UINT 4ULL
#define OP3_INST_BFE_INT  5ULL
#define OP3_INST_BFI_INT  6ULL
#define OP3_INST_BIT_ALIGN_INT  12ULL
#define OP3_INST_BYTE_ALIGN_INT 13ULL

static void patch_opcodes(char *w, unsigned remaining)
{
  uint64_t *opcode = (uint64_t *)w;
  int patched = 0;
  int count_bfe_int = 0;
  int count_bfe_uint = 0;
  int count_byte_align = 0;
  while (42) {
    int clamp = (*opcode >> (32 + 31)) & 0x1;
    int dest_rel = (*opcode >> (32 + 28)) & 0x1;
    int alu_inst = (*opcode >> (32 + 13)) & 0x1f;
    int s2_neg = (*opcode >> (32 + 12)) & 0x1;
    int s2_rel = (*opcode >> (32 + 9)) & 0x1;
    int pred_sel = (*opcode >> 29) & 0x3;
    if (!clamp && !dest_rel && !s2_neg && !s2_rel && !pred_sel) {
      if (alu_inst == OP3_INST_BFE_INT) {
        count_bfe_int++;
      } else if (alu_inst == OP3_INST_BFE_UINT) {
        count_bfe_uint++;
      } else if (alu_inst == OP3_INST_BYTE_ALIGN_INT) {
        count_byte_align++;
        // patch this instruction to BFI_INT
        *opcode &= 0xfffc1fffffffffffULL;
        *opcode |= OP3_INST_BFI_INT << (32 + 13);
        patched++;
      }
    }
    if (remaining <= 8)
      break;
    opcode++;
    remaining -= 8;
  }
  applog(LOG_DEBUG, "Potential OP3 instructions identified: "
    "%i BFE_INT, %i BFE_UINT, %i BYTE_ALIGN",
    count_bfe_int, count_bfe_uint, count_byte_align);
  applog(LOG_DEBUG, "Patched a total of %i BFI_INT instructions", patched);
}

bool kernel_bfi_patch(char *binary, unsigned binary_size)
{
  unsigned remaining = binary_size;
  char *w = binary;
  unsigned int start, length;

  /* Find 2nd incidence of .text, and copy the program's
  * position and length at a fixed offset from that. Then go
  * back and find the 2nd incidence of \x7ELF (rewind by one
  * from ELF) and then patch the opcocdes */
  if (!advance(&w, &remaining, ".text"))
    return false;
  w++; remaining--;
  if (!advance(&w, &remaining, ".text")) {
    /* 32 bit builds only one ELF */
    w--; remaining++;
  }
  memcpy(&start, w + 285, 4);
  memcpy(&length, w + 289, 4);
  w = binary; remaining = binary_size;
  if (!advance(&w, &remaining, "ELF"))
    return false;
  w++; remaining--;
  if (!advance(&w, &remaining, "ELF")) {
    /* 32 bit builds only one ELF */
    w--; remaining++;
  }
  w--; remaining++;
  w += start; remaining -= start;
  applog(LOG_DEBUG, "At %p (%u rem. bytes), to begin patching",
    w, remaining);
  patch_opcodes(w, length);

  return true;
}
