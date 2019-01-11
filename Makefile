.PHONY: build clean

build:
	hugo -s .

clean:
	rm -rf public/*
