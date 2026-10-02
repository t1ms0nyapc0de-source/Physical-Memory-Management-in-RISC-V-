# RV32 test-state structure used by pmm_selftest.S.
# This is the assembly equivalent of:
# struct pmm_test_state {
#     uint32_t expected;
#     uint32_t actual;
#     uint32_t checks_passed;
#     uint32_t checks_failed;
# };
.equ PMM_TEST_EXPECTED,      0
.equ PMM_TEST_ACTUAL,        4
.equ PMM_TEST_CHECKS_PASSED, 8
.equ PMM_TEST_CHECKS_FAILED, 12
.equ PMM_TEST_STATE_SIZE,   16

# Relevant Multiboot v1 information-structure offsets. Fields not consumed by
# pmm_init are represented as padding in pmm_selftest.S so these offsets match
# the boot protocol exactly.
.equ PMM_MBI_FLAGS,        0
.equ PMM_MBI_MEM_LOWER,    4
.equ PMM_MBI_MEM_UPPER,    8
.equ PMM_MBI_MODS_COUNT,  20
.equ PMM_MBI_MODS_ADDR,   24
.equ PMM_MBI_MMAP_LENGTH, 44
.equ PMM_MBI_MMAP_ADDR,   48
.equ PMM_MBI_SIZE,        52
.equ PMM_MBI_FLAG_MEM,     1
.equ PMM_MBI_FLAG_MMAP,   64

# Multiboot v1 memory-map entry: size excludes its own four-byte field.
.equ PMM_MMAP_SIZE,        0
.equ PMM_MMAP_BASE_LOW,    4
.equ PMM_MMAP_BASE_HIGH,   8
.equ PMM_MMAP_LENGTH_LOW, 12
.equ PMM_MMAP_LENGTH_HIGH,16
.equ PMM_MMAP_TYPE,       20
.equ PMM_MMAP_ENTRY_BYTES,24
