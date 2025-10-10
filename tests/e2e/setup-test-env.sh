#!/usr/bin/env bash
# E2E Test Environment Setup
# Sets up a clean test environment for GitHub PR workflow tests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
export TEST_FEATURE="${TEST_FEATURE:-test-e2e-$(date +%s)}"
export FRAMEWORK_ROOT="${FRAMEWORK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export TEST_REPO_DIR="${TEST_REPO_DIR:-$(mktemp -d)}"

echo -e "${GREEN}Setting up E2E test environment...${NC}"
echo "  Feature: ${TEST_FEATURE}"
echo "  Framework root: ${FRAMEWORK_ROOT}"
echo "  Test repo: ${TEST_REPO_DIR}"

# Verify prerequisites
check_prerequisites() {
  echo -e "\n${YELLOW}Checking prerequisites...${NC}"

  # Check git
  if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    exit 1
  fi

  # Check gh CLI
  if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install with: brew install gh"
    exit 1
  fi

  # Check jq
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "Install with: brew install jq"
    exit 1
  fi

  # Check gh auth
  if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI not authenticated${NC}"
    echo "Run: gh auth login"
    exit 1
  fi

  echo -e "${GREEN}✓ All prerequisites met${NC}"
}

# Initialize test repository
init_test_repo() {
  echo -e "\n${YELLOW}Initializing test repository...${NC}"

  cd "${TEST_REPO_DIR}"

  # Initialize git repo
  git init -b main
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "# Test Repository" > README.md
  git add README.md
  git commit -m "Initial commit"

  # Copy framework files to test repo
  cp -r "${FRAMEWORK_ROOT}/scripts" ./
  cp -r "${FRAMEWORK_ROOT}/commands" ./
  mkdir -p ./specs

  # Create .gitignore
  cat > .gitignore <<EOF
.DS_Store
node_modules/
*.log
.env
EOF

  git add .
  git commit -m "Add framework files"

  echo -e "${GREEN}✓ Test repository initialized at ${TEST_REPO_DIR}${NC}"
}

# Setup test fixtures
setup_fixtures() {
  echo -e "\n${YELLOW}Setting up test fixtures...${NC}"

  # Copy fixtures to test repo
  if [ -d "${FRAMEWORK_ROOT}/tests/fixtures/github-prs" ]; then
    cp -r "${FRAMEWORK_ROOT}/tests/fixtures/github-prs" "${TEST_REPO_DIR}/specs/"
    echo -e "${GREEN}✓ Test fixtures copied${NC}"
  else
    echo -e "${YELLOW}! No test fixtures found, skipping${NC}"
  fi
}

# Export environment variables for tests
export_test_vars() {
  echo -e "\n${YELLOW}Exporting test variables...${NC}"

  cat > "${TEST_REPO_DIR}/.test-env" <<EOF
export TEST_FEATURE="${TEST_FEATURE}"
export FRAMEWORK_ROOT="${FRAMEWORK_ROOT}"
export TEST_REPO_DIR="${TEST_REPO_DIR}"
export GH_MOCK_MODE="false"
EOF

  echo -e "${GREEN}✓ Test environment variables exported${NC}"
}

# Main setup flow
main() {
  check_prerequisites
  init_test_repo
  setup_fixtures
  export_test_vars

  echo -e "\n${GREEN}✓ E2E test environment ready!${NC}"
  echo -e "${YELLOW}Test repo location: ${TEST_REPO_DIR}${NC}"
  echo -e "${YELLOW}To run tests: cd ${TEST_REPO_DIR} && bats ${FRAMEWORK_ROOT}/tests/e2e/*.bats${NC}"
}

# Only run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
