ASM = nasm
ASMFLAGS = -f elf64
LD = ld
TARGET = lowmonitor

all: $(TARGET)

$(TARGET): lowmonitor_4_5.o
	$(LD) -o $(TARGET) lowmonitor_4_5.o

lowmonitor_4_5.o: lowmonitor_4_5.asm
	$(ASM) $(ASMFLAGS) lowmonitor_4_5.asm -o lowmonitor_4_5.o

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f *.o $(TARGET)
