CROSS ?= riscv64-unknown-elf-
QEMU ?= qemu-system-riscv32
ASFLAGS := -march=rv32i -mabi=ilp32

.PHONY: selftest run check clean

selftest: pmm_selftest.elf

pmm_selftest.elf: pmm_selftest.S PMM pmm_test_layout.inc pmm_selftest.ld
	$(CROSS)gcc $(ASFLAGS) -nostdlib -nostartfiles -T pmm_selftest.ld -o $@ pmm_selftest.S

run: pmm_selftest.elf
	$(QEMU) -machine virt -bios none -kernel $< -nographic

# The guest halts after printing its result, so treat timeout as normal only
# when the expected PASS line was observed.
check: pmm_selftest.elf
	@set +e; output=$$(timeout 5s $(QEMU) -machine virt -bios none -kernel $< -nographic 2>&1); status=$$?; printf '%s\n' "$$output"; printf '%s\n' "$$output" | grep -Fq 'PMM Multiboot self-test: PASS (9/9 checks)' || exit 1; test $$status -eq 0 -o $$status -eq 124

clean:
	$(RM) pmm_selftest.elf
