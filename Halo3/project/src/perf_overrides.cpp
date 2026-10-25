// Host replacements for hot guest functions (strong definitions override the
// recompiler's weak ones).

#include "generated/default/halo3_pch.h"

#include <cstring>

REX_EXTERN(__imp__sub_825A18C0);

// sub_825A18C0: the game's VMX block copy (r3 = destination, r4 = source,
// r5 = size, whole 128-byte lines). The main thread spends ~38% of its time in
// it (per-vector byte shuffles, plus dcbzl zeroing every line before it is
// written). Same result with one host memmove when the arguments are the
// aligned whole-line copies it is written for; anything else goes to the
// original.
extern "C" REX_FUNC(sub_825A18C0) {
  const uint32_t dst = ctx.r3.u32;
  const uint32_t src = ctx.r4.u32;
  const uint32_t size = ctx.r5.u32;
  const bool phys_split =
      REX_PHYS_HOST_OFFSET(dst) != REX_PHYS_HOST_OFFSET(dst + size - 1) ||
      REX_PHYS_HOST_OFFSET(src) != REX_PHYS_HOST_OFFSET(src + size - 1);
  if (!size || (size & 127) || (dst & 127) || (src & 15) || phys_split) {
    __imp__sub_825A18C0(ctx, base);
    return;
  }
  std::memmove(REX_RAW_ADDR(dst), REX_RAW_ADDR(src), size);
  // Register state the original leaves behind.
  ctx.r3.u64 = uint64_t(dst) + size;
  ctx.r4.u64 = uint64_t(src) + size;
  ctx.r5.u64 = 0;
  ctx.r6.u64 = 16;
  ctx.r7.u64 = 32;
  ctx.r8.u64 = 48;
  ctx.r9.u64 = 64;
  ctx.r10.u64 = 80;
  ctx.r11.u64 = 96;
  ctx.r12.u64 = 112;
}
