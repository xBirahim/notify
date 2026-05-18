.PHONY: build run test release install clean

build:
	swift build

run:
	swift run notifyctl --help

test:
	swift test

release:
	swift build -c release

install: release
	install -m 755 .build/release/notifyctl /usr/local/bin/notifyctl

clean:
	swift package clean
