.PHONY: build run test release install install-app install-link clean

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

install-app: release
	mkdir -p /Applications/NotifyCtl.app/Contents/MacOS
	mkdir -p /Applications/NotifyCtl.app/Contents
	cp .build/release/notifyctl /Applications/NotifyCtl.app/Contents/MacOS/notifyctl
	chmod 755 /Applications/NotifyCtl.app/Contents/MacOS/notifyctl
	printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' '<plist version="1.0"><dict><key>CFBundleExecutable</key><string>notifyctl</string><key>CFBundleIdentifier</key><string>io.notifyctl.app</string><key>CFBundleName</key><string>NotifyCtl</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.1.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>' > /Applications/NotifyCtl.app/Contents/Info.plist

install-link:
	ln -sf /Applications/NotifyCtl.app/Contents/MacOS/notifyctl /usr/local/bin/notifyctl

clean:
	swift package clean
