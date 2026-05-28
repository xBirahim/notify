PREFIX ?= $(HOME)/.local
BUNDLE_DIR = $(PREFIX)/share/Notify.app
BIN_DIR = $(PREFIX)/bin

.PHONY: build run test release install bundle link clean

build:
	swift build

run:
	swift run notify --help

test:
	swift test

release:
	swift build -c release

install: bundle link
	@echo ""
	@echo "  notify installed!"
	@echo ""
	@echo "  Add to your shell config (e.g. ~/.zshrc):"
	@echo '    export PATH="$$HOME/.local/bin:$$PATH"'
	@echo ""
	@echo "  Then run:"
	@echo "    notify status"
	@echo "    notify request-permission"
	@echo "    notify send \"Build terminé\""
	@echo ""

bundle: release
	mkdir -p "$(BUNDLE_DIR)/Contents/MacOS"
	cp .build/release/notify "$(BUNDLE_DIR)/Contents/MacOS/notify"
	chmod 755 "$(BUNDLE_DIR)/Contents/MacOS/notify"
	printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' '<plist version="1.0"><dict><key>CFBundleExecutable</key><string>notify</string><key>CFBundleIdentifier</key><string>io.notify.app</string><key>CFBundleName</key><string>Notify</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.2.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>' > "$(BUNDLE_DIR)/Contents/Info.plist"
	codesign -s - --force --deep "$(BUNDLE_DIR)" 2>/dev/null || true
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$(BUNDLE_DIR)" 2>/dev/null || true
	@echo "Created $(BUNDLE_DIR)"

link:
	mkdir -p "$(BIN_DIR)"
	printf '%s\n' '#!/bin/sh' 'exec "$(BUNDLE_DIR)/Contents/MacOS/notify" "$$@"' > "$(BIN_DIR)/notify"
	chmod 755 "$(BIN_DIR)/notify"
	@echo "Created $(BIN_DIR)/notify"

clean:
	swift package clean
