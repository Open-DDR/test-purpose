# Makefile for openddr DDR SystemC-QEMU Bridge

# SystemC installation path - adjust as needed
SYSTEMC_HOME ?= /aws/home/jayb/systemc-2.3.3
SYSTEMC_ARCH ?= linux64

# Compiler settings
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2 -pthread
INCLUDES = -I$(SYSTEMC_HOME)/include -I../../src -I.
LDFLAGS = -L$(SYSTEMC_HOME)/lib-$(SYSTEMC_ARCH) -pthread
LIBS = -lsystemc -lm

# Source files
BRIDGE_SOURCES = qemu_systemc_bridge.cpp openddr_systemc_server.cpp
BRIDGE_OBJECTS = $(BRIDGE_SOURCES:.cpp=.o)

# Enhanced SystemC model sources (from ../src) - Using verification disabled version
MODEL_SOURCES = ../../src/openddr_systemc_model_verification_disabled.cpp
MODEL_OBJECTS = $(MODEL_SOURCES:.cpp=.o)

# All objects
ALL_OBJECTS = $(BRIDGE_OBJECTS) $(MODEL_OBJECTS)

# Executables
SERVER_TARGET = openddr_systemc_server
TEST_CLIENT_TARGET = test_client

# Default target
all: $(SERVER_TARGET) $(TEST_CLIENT_TARGET)

# Server executable
$(SERVER_TARGET): $(ALL_OBJECTS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)

# Test client
$(TEST_CLIENT_TARGET): test_client.o
	$(CXX) -pthread -o $@ $^

# Object file rules
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Model object files (from ../src)
../../src/%.o: ../../src/%.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Dependencies
qemu_systemc_bridge.o: qemu_systemc_bridge.cpp qemu_systemc_bridge.h ../../src/openddr_systemc_model_enhanced.h
openddr_systemc_server.o: openddr_systemc_server.cpp qemu_systemc_bridge.h
test_client.o: test_client.cpp qemu_systemc_bridge.h

# Test targets
test: $(SERVER_TARGET) $(TEST_CLIENT_TARGET)
	@echo "Starting SystemC server in background..."
	./$(SERVER_TARGET) --port 8888 --memory-size 512 &
	@SERVER_PID=$$!; \
	sleep 2; \
	echo "Running test client..."; \
	./$(TEST_CLIENT_TARGET) --server localhost:8888 --test basic; \
	echo "Stopping server..."; \
	kill $$SERVER_PID 2>/dev/null || true

# Performance test
perf-test: $(SERVER_TARGET) $(TEST_CLIENT_TARGET)
	@echo "Starting performance test..."
	./$(SERVER_TARGET) --port 8889 --memory-size 1024 &
	@SERVER_PID=$$!; \
	sleep 2; \
	./$(TEST_CLIENT_TARGET) --server localhost:8889 --test performance; \
	kill $$SERVER_PID 2>/dev/null || true

# Memory test
mem-test: $(SERVER_TARGET)
	@if command -v valgrind >/dev/null 2>&1; then \
		echo "Running memory leak test..."; \
		valgrind --leak-check=full --show-leak-kinds=all ./$(SERVER_TARGET) --port 8890 --memory-size 256 & \
		SERVER_PID=$$!; \
		sleep 5; \
		kill $$SERVER_PID 2>/dev/null || true; \
	else \
		echo "Valgrind not available, skipping memory test"; \
	fi

# Debug build
debug: CXXFLAGS += -DDEBUG -g -O0
debug: clean $(SERVER_TARGET) $(TEST_CLIENT_TARGET)

# Release build
release: CXXFLAGS += -DNDEBUG -O3
release: clean $(SERVER_TARGET) $(TEST_CLIENT_TARGET)

# Install target
install: $(SERVER_TARGET)
	@echo "Installing openddr SystemC Server..."
	mkdir -p $(HOME)/bin
	cp $(SERVER_TARGET) $(HOME)/bin/
	@echo "Installation completed to $(HOME)/bin/"

# Clean targets
clean:
	rm -f *.o ../../src/*.o

clean-all: clean
	rm -f $(SERVER_TARGET) $(TEST_CLIENT_TARGET)
	rm -f *.vcd *.log

# Documentation
docs:
	@if command -v doxygen >/dev/null 2>&1; then \
		echo "Generating documentation..."; \
		doxygen Doxyfile 2>/dev/null || echo "Using default doxygen settings"; \
		echo "Documentation generated in docs/ directory"; \
	else \
		echo "Doxygen not available, skipping documentation generation"; \
	fi

# Static analysis
lint:
	@if command -v cppcheck >/dev/null 2>&1; then \
		echo "Running static analysis..."; \
		cppcheck --enable=all --std=c++17 --suppress=missingIncludeSystem $(BRIDGE_SOURCES); \
	else \
		echo "cppcheck not available, skipping lint check"; \
	fi

# Format code
format:
	@if command -v clang-format >/dev/null 2>&1; then \
		echo "Formatting code..."; \
		clang-format -i *.cpp *.h; \
		echo "Code formatting completed"; \
	else \
		echo "clang-format not available, skipping code formatting"; \
	fi

# Help target
help:
	@echo "openddr DDR SystemC-QEMU Bridge - Makefile"
	@echo "=============================================="
	@echo "Available targets:"
	@echo "  all           - Build server and test client"
	@echo "  $(SERVER_TARGET) - Build SystemC server"
	@echo "  $(TEST_CLIENT_TARGET)   - Build test client"
	@echo "  test          - Run basic functionality test"
	@echo "  perf-test     - Run performance test"
	@echo "  mem-test      - Run memory leak test (requires valgrind)"
	@echo "  debug         - Build debug version"
	@echo "  release       - Build optimized release version"
	@echo "  clean         - Remove object files"
	@echo "  clean-all     - Remove all generated files"
	@echo "  install       - Install to ~/bin"
	@echo "  docs          - Generate documentation (requires doxygen)"
	@echo "  lint          - Run static analysis (requires cppcheck)"
	@echo "  format        - Format code (requires clang-format)"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Environment variables:"
	@echo "  SYSTEMC_HOME  - Path to SystemC installation"
	@echo "  SYSTEMC_ARCH  - SystemC architecture (default: linux64)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make all                    # Build everything"
	@echo "  make test                   # Run basic test"
	@echo "  make SYSTEMC_HOME=/opt/systemc release  # Custom SystemC path"

# Phony targets
.PHONY: all test perf-test mem-test debug release clean clean-all install docs lint format help

# Default goal
.DEFAULT_GOAL := all
