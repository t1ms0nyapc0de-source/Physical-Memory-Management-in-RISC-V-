# PMM assembly self-test

`PMM` is a physical-memory manager (PMM), not a virtual-memory manager
(VMM).  It allocates 4 KiB physical frames using bitmaps.  A VMM proof would
also require page tables, an `satp` write, `sfence.vma`, and translated-memory
accesses; none of those are in this repository.

`pmm_selftest.S` is an RV32I bare-metal integration test. It defines an
in-memory Multiboot v1 information structure and a 24-byte Multiboot memory-
map entry, then calls `pmm_init(&pmm_test_mboot_info)`. The map declares the
QEMU `virt` RAM interval `0x80000000..0x80800000` as usable. The PMM must
discover its upper bound, create both bitmap arrays after `_kernel_end`, and
reserve the kernel and bitmap pages before the allocation checks run.

The state layout in `pmm_test_layout.inc` is the assembly equivalent of this
structure:

```c
struct pmm_test_state {
    uint32_t expected;
    uint32_t actual;
    uint32_t checks_passed;
    uint32_t checks_failed;
};
```

It verifies the memory-map-derived frame total, bitmap initialization, two
nonzero distinct allocations, allocation-bitmap ownership, free-and-reuse,
protection of the bitmap-reserved page, and out-of-range rejection.

## Run

Install an RV32 bare-metal GNU toolchain and QEMU, then from this directory:

```sh
make selftest CROSS=riscv64-unknown-elf-
make run
```

For a non-interactive pass/fail run that exits automatically, use `make check`.
It runs QEMU for up to five seconds, requires the exact PASS line, and returns
a failing status if the guest does not print it.

For a toolchain named `riscv32-unknown-elf-gcc`, use
`CROSS=riscv32-unknown-elf-` instead.  Exit QEMU with `Ctrl-A`, then `X`.

The correct serial output is exactly:

```text
PMM Multiboot self-test: PASS (9/9 checks)
```

On failure the test remains halted; inspect `pmm_test_state` in GDB.  Its
`checks_failed` is nonzero, while `expected` and `actual` hold the most recent
failed comparison.
