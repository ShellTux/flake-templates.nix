TARGETS = \
					$(TARGET_DIR)/c-example \
					$(TARGET_DIR)/cpp-example

DEPS := src/c-example.c src/example.c
$(TARGET_DIR)/c-example: $(DEPS:%.c=$(BUILD_DIR)/%.o)
	@mkdir --parents $(shell dirname $@)
	$(CC) -o $@ $^ $(LDFLAGS)

DEPS := src/cpp-example.cpp
$(TARGET_DIR)/cpp-example: $(DEPS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir --parents $(shell dirname $@)
	$(CXX) -o $@ $^ $(LDFLAGS)
