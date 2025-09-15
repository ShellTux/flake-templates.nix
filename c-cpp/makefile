CC  = gcc
CXX = g++

MODE ?= DEBUG

INCLUDE_DIR = include

.PHONY: all
all:
	$(MAKE) --no-print-directory MODE=DEBUG build
	$(MAKE) --no-print-directory MODE=RELEASE build

CFLAGS += -Wall -Wextra -Werror
CFLAGS += -I$(INCLUDE_DIR)
CFLAGS += -std=c99

CXXFLAGS += -Wall -Wextra -Werror
CXXFLAGS += -I$(INCLUDE_DIR)
CXXFLAGS += -std=c++17

ifeq ($(MODE), DEBUG)
	include debug.mk
endif
ifeq ($(MODE), RELEASE)
	include release.mk
endif

ifndef BUILD_DIR
$(error BUILD_DIR is not defined)
endif

ifndef TARGET_DIR
$(error TARGET_DIR is not defined)
endif

include targets.mk

ifndef TARGETS
$(error TARGETS are not defined)
endif

OUTPUT_OPTION = -MMD -MF $(@:.o=.d) -o $@

DEPS := $(shell find $(BUILD_DIR) -name "*.d" 2>/dev/null)
-include ${DEPS}

.PHONY: build
build: $(TARGETS)

.PHONY: b
b: build

.PHONY: run
run: $(TARGETS)
	@for target in $(TARGETS); do (set -x; ./$$target) ; done

.PHONY: r
r: run

$(BUILD_DIR)/%.o: src/%.cpp
	@mkdir --parents $(shell dirname $@)
	$(CXX) $(CXXFLAGS) -MMD -MF $(@:.o=.d) -c -o $@ $<

$(BUILD_DIR)/%.o: src/%.c
	@mkdir --parents $(shell dirname $@)
	$(CC) $(CFLAGS) -MMD -MF $(@:.o=.d) -c -o $@ $<

.PHONY: clean
clean:
	rm --force --recursive $(BUILD_DIR) $(TARGET_DIR)

.PHONY: vars
vars:
	@echo BUILD_DIR=$(BUILD_DIR)
	@echo TARGET_DIR=$(TARGET_DIR)
	@echo CC=$(CC)
	@echo CFLAGS=$(CFLAGS)
	@echo CXX=$(CXX)
	@echo CXXFLAGS=$(CXXFLAGS)
	@echo INCLUDE_DIR=$(INCLUDE_DIR)
	@echo LDFLAGS=$(LDFLAGS)
	@echo MODE=$(MODE)
	@echo TARGETS=$(TARGETS)
