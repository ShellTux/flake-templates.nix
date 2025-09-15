CFLAGS += -DDEBUG
CFLAGS += -ggdb

CXXFLAGS += -DDEBUG
CXXFLAGS += -ggdb

LDFLAGS += -fsanitize=address
LDFLAGS += -fsanitize=leak

BUILD_DIR = build/debug
TARGET_DIR = target/debug
