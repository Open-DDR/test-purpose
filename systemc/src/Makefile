# Makefile for Whitney LPDDR5 SystemC Model
# Requires SystemC installation

# SystemC installation path - modify as needed
SYSTEMC_HOME ?= /usr/local/systemc-2.3.3
SYSTEMC_ARCH ?= linux64

# Compiler settings
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
INCLUDES = -I$(SYSTEMC_HOME)/include -I.
LDFLAGS = -L$(SYSTEMC_HOME)/lib-$(SYSTEMC_ARCH)
LIBS = -lsystemc -lm

# Source files
SRCS = whitney_systemc_model.cpp whitney_testbench.cpp
OBJS = $(SRCS:.cpp=.o)
TARGET = whitney_simulation

# Default target
all: $(TARGET)

# Build the executable
$(TARGET): $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)

# Compile source files
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Clean build artifacts
clean:
	rm -f $(OBJS) $(TARGET) *.vcd

# Run simulation
run: $(TARGET)
	./$(TARGET)

# View waveforms (requires GTKWave)
wave: whitney_trace.vcd
	gtkwave whitney_trace.vcd &

# Install dependencies (Ubuntu/Debian)
install-deps:
	sudo apt-get update
	sudo apt-get install build-essential gtkwave

# Help
help:
	@echo "Available targets:"
	@echo "  all        - Build the simulation executable"
	@echo "  clean      - Remove build artifacts"
	@echo "  run        - Run the simulation"
	@echo "  wave       - View waveforms with GTKWave"
	@echo "  install-deps - Install required packages (Ubuntu/Debian)"
	@echo ""
	@echo "Environment variables:"
	@echo "  SYSTEMC_HOME - Path to SystemC installation (default: /usr/local/systemc-2.3.3)"
	@echo "  SYSTEMC_ARCH - SystemC architecture (default: linux64)"

.PHONY: all clean run wave install-deps help
