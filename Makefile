.PHONY: build clean

build:
	hugo -d build

clean:
	rm -rf build/*
