.PHONY: help build release test clean format lint install uninstall docs

help:
	@echo "PermissionPilot - Makefile Commands"
	@echo "===================================="
	@echo ""
	@echo "Development:"
	@echo "  make build       - Build debug version"
	@echo "  make release     - Build release version"
	@echo "  make test        - Run all tests"
	@echo "  make coverage    - Generate coverage report"
	@echo ""
	@echo "Code Quality:"
	@echo "  make format      - Format code (SwiftFormat)"
	@echo "  make lint        - Lint code (SwiftLint)"
	@echo "  make clean-lint  - Auto-fix linting issues"
	@echo ""
	@echo "Installation:"
	@echo "  make install     - Install to /Applications"
	@echo "  make uninstall   - Remove from /Applications"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make docs        - Generate documentation"
	@echo "  make sign        - Sign for distribution"
	@echo ""

# Development targets
build:
	./Scripts/build.sh debug

release:
	./Scripts/build.sh release

test:
	xcodebuild test -scheme PermissionPilot -destination 'platform=macOS'

coverage:
	xcodebuild test \
		-scheme PermissionPilot \
		-enableCodeCoverage YES \
		-destination 'platform=macOS'

# Code quality
format:
	@command -v swiftformat >/dev/null 2>&1 || { echo "Installing SwiftFormat..."; brew install swiftformat; }
	swiftformat Sources/ Tests/ --recursive

lint:
	@command -v swiftlint >/dev/null 2>&1 || { echo "Installing SwiftLint..."; brew install swiftlint; }
	swiftlint lint Sources/ Tests/ --reporter github-actions-logging

clean-lint:
	@command -v swiftlint >/dev/null 2>&1 || { echo "Installing SwiftLint..."; brew install swiftlint; }
	swiftlint lint Sources/ Tests/ --fix

# Installation
install: release
	@echo "Installing PermissionPilot to /Applications..."
	ditto build/Export/PermissionPilot.app /Applications/PermissionPilot.app
	@echo "Installation complete!"

uninstall:
	@echo "Removing PermissionPilot from /Applications..."
	rm -rf /Applications/PermissionPilot.app
	rm -rf ~/Library/Application\ Support/PermissionPilot
	rm -rf ~/Library/Preferences/com.permissionpilot.*
	@echo "Uninstall complete!"

# Maintenance
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf .build/
	xcodebuild clean -scheme PermissionPilot
	@echo "Clean complete!"

docs:
	@echo "Generating documentation..."
	@echo "Documentation is available in README.md, ARCHITECTURE.md, etc."

sign:
	@echo "Use Scripts/sign-and-notarize.sh for production signing"
	@echo "  ./Scripts/sign-and-notarize.sh <archive> <apple-id> <password> <team-id>"

# Shortcuts
all: clean format lint test build
	@echo "Build complete!"

run: build
	open build/DerivedData/Build/Products/Debug/PermissionPilot.app

debug: clean format lint test build run
