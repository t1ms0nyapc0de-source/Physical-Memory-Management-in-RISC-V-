CROSS ?= riscv64-unknown-elf-
ASFLAGS := -march=rv32i -mabi=ilp32

.PHONY: selftest run clean

selftest: pmm_selftest.elf

pmm_selftest.elf: pmm_selftest.S PMM pmm_test_layout.inc pmm_selftest.ld
	$(CROSS)gcc $(ASFLAGS) -nostdlib -nostartfiles -T pmm_selftest.ld -o $@ pmm_selftest.S

run: pmm_selftest.elf
	qemu-system-riscv32 -machine virt -bios none -kernel $< -nographic

clean:
	$(RM) pmm_selftest.elf
