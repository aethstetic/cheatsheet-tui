DC := ldc2
DFLAGS := -O2 -release -static
DEBUGFLAGS := -g -d-debug -checkaction=context

SRCDIR := source
TARGET := cheatsheet-tui

SOURCES := $(wildcard $(SRCDIR)/*.d)

.PHONY: all clean debug

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(DC) $(DFLAGS) -of=$(TARGET) $(SOURCES)

debug: $(SOURCES)
	$(DC) $(DEBUGFLAGS) -of=$(TARGET)-debug $(SOURCES)

clean:
	rm -f $(TARGET) $(TARGET)-debug
	rm -f $(SRCDIR)/*.o
	rm -f $(TARGET).o
