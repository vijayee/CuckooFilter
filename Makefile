build:
	mkdir -p build
test: build
	mkdir -p build/test
test/CuckooFilter: test CuckooFilter/*.pony CuckooFilter/test/*.pony
	stable fetch
  stable env ponyc CuckooFilter/test -o build --debug
test/execute: test/CuckooFilter
	./build/test/test
clean:
	rm -rf build

.PHONY: clean test
