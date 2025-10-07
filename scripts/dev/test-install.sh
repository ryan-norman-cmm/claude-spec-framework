#!/bin/bash
# Test installation script - Install to isolated test directory

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing Claude Spec Framework Installation${NC}"
echo "================================================"
echo ""

# Create isolated test directory
TEST_DIR="/tmp/claude-spec-framework-test-$(date +%s)"
echo -e "${BLUE}ℹ${NC} Creating test environment: $TEST_DIR"
mkdir -p "$TEST_DIR"

# Run installation with custom CLAUDE_DIR
echo -e "${BLUE}ℹ${NC} Running installation to test directory..."
echo ""

CLAUDE_DIR="$TEST_DIR" ./scripts/install/install.sh --auto

echo ""
echo "================================================"
echo -e "${GREEN}✅ Installation test complete!${NC}"
echo ""

# Verification
echo -e "${BLUE}📋 Verification Results:${NC}"
echo ""

# Check agents
echo "Agents installed:"
ls -1 "$TEST_DIR/agents/" | wc -l | xargs echo "  -"
ls -1 "$TEST_DIR/agents/" | sed 's/^/    /'

echo ""
echo "Commands installed:"
ls -1 "$TEST_DIR/commands/spec/" | wc -l | xargs echo "  -"

echo ""
echo "Hooks installed:"
ls -1 "$TEST_DIR/hooks/"*.sh 2>/dev/null | wc -l | xargs echo "  -"

echo ""
echo "Scripts installed:"
ls -1 "$TEST_DIR/scripts/"*.sh 2>/dev/null | wc -l | xargs echo "  -"

echo ""
echo -e "${BLUE}📂 Test installation location:${NC}"
echo "  $TEST_DIR"
echo ""

echo -e "${BLUE}🔍 Inspect files:${NC}"
echo "  tree $TEST_DIR"
echo "  ls -la $TEST_DIR/agents/"
echo ""

echo -e "${BLUE}🗑️  Clean up when done:${NC}"
echo "  rm -rf $TEST_DIR"
echo ""

echo -e "${YELLOW}Note:${NC} Your current ~/.claude setup is completely untouched!"
