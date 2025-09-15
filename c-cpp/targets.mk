TARGETS = \
					$(TARGET_DIR)/c-example \
					$(TARGET_DIR)/cpp-example

DEPS := src/c-example.c src/example.c
DEPS := $(DEPS:src/%.c=$(BUILD_DIR)/%.o)
$(TARGET_DIR)/c-example: $(DEPS)
	@mkdir --parents $(shell dirname $@)
	$(CC) -o $@ $^

DEPS := src/cpp-example.cpp
DEPS := $(DEPS:src/%.cpp=$(BUILD_DIR)/%.o)
$(TARGET_DIR)/cpp-example: $(DEPS)
	@mkdir --parents $(shell dirname $@)
	$(CXX) -o $@ $^
