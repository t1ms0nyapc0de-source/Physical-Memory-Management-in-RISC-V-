# Bare-metal RV32I Multiboot-to-PMM integration test.
# PMM is included so the allocator and test are assembled into one unit.
.include "PMM"
.include "pmm_test_layout.inc"

.section .data
.align 2
# Multiboot v1 information block with one 8 MiB usable RAM entry. It is passed
# directly to pmm_init just as a Multiboot bootloader would pass it.
pmm_test_mboot_info:
    .word PMM_MBI_FLAG_MEM | PMM_MBI_FLAG_MMAP
    .word 640                                  # mem_lower, KiB
    .word 7168                                 # mem_upper, KiB
    .space 8                                   # boot_device, cmdline
    .word 0                                    # mods_count
    .word 0                                    # mods_addr
    .space 16                                  # symbol-table fields
    .word PMM_MMAP_ENTRY_BYTES                 # mmap_length
    .word pmm_test_mmap                        # mmap_addr

.align 2
pmm_test_mmap:
    .word 20                                   # size, excluding itself
    .word 0x80000000                           # base_addr_low
    .word 0                                    # base_addr_high
    .word 0x00800000                           # length_low (8 MiB)
    .word 0                                    # length_high
    .word 1                                    # type = usable RAM

.section .bss
.align 2
pmm_test_state:
    .space PMM_TEST_STATE_SIZE
.align 4
pmm_test_stack:
    .space 4096
pmm_test_stack_top:

.section .text.boot
.globl _start
_start:
    la   sp, pmm_test_stack_top
    call pmm_selftest
    beqz a0, pmm_test_halt
    la   a0, pmm_test_pass_message
    call pmm_test_puts
pmm_test_halt:
    wfi
    j    pmm_test_halt

# Returns a0 = 1 when all checks pass. _kernel_end is defined by the linker
# after .bss, so pmm_init places bitmap storage after the whole test image.
.globl pmm_selftest
pmm_selftest:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s0, 24(sp)
    sw   s1, 20(sp)
    sw   s2, 16(sp)

    la   s0, pmm_test_state
    sw   zero, PMM_TEST_CHECKS_PASSED(s0)
    sw   zero, PMM_TEST_CHECKS_FAILED(s0)
    la   a0, pmm_test_mboot_info
    call pmm_init

    # pmm_init must use the mmap end: 0x80800000 / 4096 = 0x80800.
    la   t0, pmm_total_blocks
    lw   s1, 0(t0)
    li   a0, 0x80800
    call pmm_test_expect
    la   t0, pmm_bitmap
    lw   s1, 0(t0)
    call pmm_test_expect_nonzero

    # Allocate two real frames made available through the Multiboot map.
    call pmm_alloc_block
    mv   s1, a0
    mv   s2, a0
    call pmm_test_expect_nonzero
    call pmm_alloc_block
    mv   s1, a0
    call pmm_test_expect_nonzero
    beq  s2, s1, pmm_test_record_fail
    call pmm_test_record_pass

    # The allocation bitmap marks a returned page as owned.
    srli a0, s2, 12
    call pmm_test_allocated_block
    mv   s1, a0
    li   a0, 1
    call pmm_test_expect

    # A freed frame is the next first-fit allocation.
    mv   a0, s2
    call pmm_free_block
    call pmm_alloc_block
    mv   s1, a0
    mv   a0, s2
    call pmm_test_expect

    # The bitmap page is reserved and was never allocated: it must stay used.
    la   t0, _kernel_end
    mv   s1, t0
    mv   a0, s1
    call pmm_free_block
    srli a0, s1, 12
    call pmm_test_block
    mv   s1, a0
    li   a0, 1
    call pmm_test_expect

    # A block index equal to total_blocks is invalid and reports zero.
    la   t0, pmm_total_blocks
    lw   a0, 0(t0)
    call pmm_test_block
    mv   s1, a0
    li   a0, 0
    call pmm_test_expect

    lw   t0, PMM_TEST_CHECKS_FAILED(s0)
    snez a0, t0
    xori a0, a0, 1
    j    pmm_selftest_done
pmm_selftest_done:
    lw   ra, 28(sp)
    lw   s0, 24(sp)
    lw   s1, 20(sp)
    lw   s2, 16(sp)
    addi sp, sp, 32
    ret

# Input: a0 expected, s1 actual. Records values and one result.
pmm_test_expect:
    sw   a0, PMM_TEST_EXPECTED(s0)
    sw   s1, PMM_TEST_ACTUAL(s0)
    bne  a0, s1, pmm_test_record_fail
    j    pmm_test_record_pass
pmm_test_expect_nonzero:
    bnez s1, pmm_test_record_pass
    j    pmm_test_record_fail
pmm_test_record_pass:
    lw   t0, PMM_TEST_CHECKS_PASSED(s0)
    addi t0, t0, 1
    sw   t0, PMM_TEST_CHECKS_PASSED(s0)
    ret
pmm_test_record_fail:
    lw   t0, PMM_TEST_CHECKS_FAILED(s0)
    addi t0, t0, 1
    sw   t0, PMM_TEST_CHECKS_FAILED(s0)
    ret

# QEMU virt's NS16550A UART at 0x10000000. a0 is an ASCII byte.
pmm_test_putc:
    li   t0, 0x10000000
pmm_test_uart_wait:
    lbu  t1, 5(t0)
    andi t1, t1, 0x20
    beqz t1, pmm_test_uart_wait
    sb   a0, 0(t0)
    ret

# a0 = NUL-terminated string
pmm_test_puts:
    addi sp, sp, -16
    sw   ra, 12(sp)
    mv   t2, a0
pmm_test_puts_loop:
    lbu  a0, 0(t2)
    beqz a0, pmm_test_puts_done
    call pmm_test_putc
    addi t2, t2, 1
    j    pmm_test_puts_loop
pmm_test_puts_done:
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

.section .rodata
pmm_test_pass_message:
    .asciz "PMM Multiboot self-test: PASS (9/9 checks)\r\n"
