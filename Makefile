# Copyright (C) 2023 Toitware ApS.
# Use of this source code is governed by a Zero-Clause BSD license that can
# be found in the tests/LICENSE file.

all: test

.PHONY: build/host/CMakeCache.txt
build/CMakeCache.txt:
	$(MAKE) rebuild-cmake

install-pkgs: rebuild-cmake
	cmake --build build --target install-pkgs

test: install-pkgs rebuild-cmake
	cmake --build build --target check

# We rebuild the cmake file all the time.
# We use "glob" in the cmakefile, and wouldn't otherwise notice if a new
# file (for example a test) was added or removed.
# It takes <1s on Linux to run cmake, so it doesn't hurt to run it frequently.
rebuild-cmake:
	mkdir -p build
	# We need to set a build type, otherwise cmake won't run nicely on Windows.
	# The build-type is otherwise unused.
	cmake -B build -DCMAKE_BUILD_TYPE=Debug

.PHONY: all test rebuild-cmake install-pkgs
