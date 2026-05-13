#!/bin/bash

# Setup script for PermissionPilot development environment
# Run: ./Scripts/setup-dev.sh

set -e

echo "🚀 Setting up PermissionPilot development environment..."
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Install from https://brew.sh"
    exit 1
fi

# Install development tools
echo "📦 Installing development tools..."
brew install swiftformat swiftlint pre-commit shellcheck yamllint
echo "✅ Development tools installed"
echo ""

# Install pre-commit hooks
echo "🪝 Setting up pre-commit hooks..."
pre-commit install
echo "✅ Pre-commit hooks installed"
echo ""

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p ~/Library/Logs/PermissionPilot
echo "✅ Logs directory created"
echo ""

# Setup git hooks
echo "🔧 Configuring git..."
git config commit.template .gitmessage 2>/dev/null || true
echo "✅ Git configured"
echo ""

echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Build the project:    make build"
echo "  2. Run tests:            make test"
echo "  3. Format code:          make format"
echo "  4. Lint code:            make lint"
echo ""
echo "Pre-commit hooks are now active. They will run automatically on commit."
echo "To skip hooks (not recommended): git commit --no-verify"
echo ""
