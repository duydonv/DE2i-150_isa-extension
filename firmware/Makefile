CROSS ?= riscv64-unknown-elf-
MEM_WORDS ?= 8192

CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy

ARCH_FLAGS := -march=rv32i -mabi=ilp32
CFLAGS     := -Os -ffreestanding -nostdlib -Wall -Wextra $(ARCH_FLAGS)
LDFLAGS    := -Wl,--build-id=none,-Bstatic,-T,sections.lds,--strip-debug

.PHONY: all clean

all: firmware.hex firmware_byte0.hex firmware_byte1.hex firmware_byte2.hex firmware_byte3.hex firmware.bin

firmware.elf: start.s main.c sections.lds
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ start.s main.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 -c "from pathlib import Path; data = Path('firmware.bin').read_bytes(); data += b'\\x00' * ((4 - len(data) % 4) % 4); Path('firmware.hex').write_text(''.join(f'{int.from_bytes(data[i:i+4], \"little\"):08x}\\n' for i in range(0, len(data), 4)))"

firmware_byte0.hex firmware_byte1.hex firmware_byte2.hex firmware_byte3.hex: firmware.bin
	python3 -c "from pathlib import Path; depth = int('$(MEM_WORDS)'); data = Path('firmware.bin').read_bytes(); data += b'\\x00' * ((4 - len(data) % 4) % 4); words = [data[i:i+4] for i in range(0, len(data), 4)]; words += [b'\\x00\\x00\\x00\\x00'] * (depth - len(words)); lanes = [Path(f'firmware_byte{n}.hex') for n in range(4)]; [lanes[n].write_text(''.join(f'{w[n]:02x}\\n' for w in words[:depth])) for n in range(4)]"

clean:
	rm -f firmware.elf firmware.bin firmware.hex firmware_byte0.hex firmware_byte1.hex firmware_byte2.hex firmware_byte3.hex
