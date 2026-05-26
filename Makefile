PREFIX ?= $(HOME)/.local
BUNDLE_DIR = $(PREFIX)/share/NotifyCtl.app
BIN_DIR = $(PREFIX)/bin

.PHONY: build run test release install bundle link clean

build:
	swift build

run:
	swift run notifyctl --help

test:
	swift test

release:
	swift build -c release

install: bundle link
	@echo ""
	@echo "  notifyctl installed!"
	@echo ""
	@echo "  Add to your shell config (e.g. ~/.zshrc):"
	@echo '    export PATH="$$HOME/.local/bin:$$PATH"'
	@echo ""
	@echo "  Then run:"
	@echo "    notifyctl status"
	@echo "    notifyctl request-permission"
	@echo "    notifyctl send \"Build terminé\""
	@echo ""

bundle: release
	mkdir -p "$(BUNDLE_DIR)/Contents/MacOS"
	cp .build/release/notifyctl "$(BUNDLE_DIR)/Contents/MacOS/notifyctl"
	chmod 755 "$(BUNDLE_DIR)/Contents/MacOS/notifyctl"
	printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' '<plist version="1.0"><dict><key>CFBundleExecutable</key><string>notifyctl</string><key>CFBundleIdentifier</key><string>io.notifyctl.app</string><key>CFBundleName</key><string>NotifyCtl</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.2.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>' > "$(BUNDLE_DIR)/Contents/Info.plist"
	codesign -s - --force --deep "$(BUNDLE_DIR)" 2>/dev/null || true
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$(BUNDLE_DIR)" 2>/dev/null || true
	@echo "Created $(BUNDLE_DIR)"

link:
	mkdir -p "$(BIN_DIR)"
	printf '%s\n' '#!/bin/sh' 'exec "$(BUNDLE_DIR)/Contents/MacOS/notifyctl" "$$@"' > "$(BIN_DIR)/notifyctl"
	chmod 755 "$(BIN_DIR)/notifyctl"
	@echo "Created $(BIN_DIR)/notifyctl"

clean:
	swift package clean
