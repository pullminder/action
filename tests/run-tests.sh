#!/bin/bash
# Test runner for pullminder/action

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_HELPER="${SCRIPT_DIR}/test-helper.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "=========================================="
echo "Pullminder Action Test Suite"
echo "=========================================="
echo -e "${NC}"

# Source test helper to initialize counters
source "$TEST_HELPER"

# Run unit tests
echo -e "${YELLOW}Running unit tests...${NC}"
echo ""

for test_file in "${SCRIPT_DIR}/unit"/*.test.sh; do
    if [ -f "$test_file" ]; then
        echo -e "${BLUE}Executing: $(basename "$test_file")${NC}"
        source "$test_file"
    fi
done

# Run integration tests
echo ""
echo -e "${YELLOW}Running integration tests...${NC}"
echo ""

for test_file in "${SCRIPT_DIR}/integration"/*.test.sh; do
    if [ -f "$test_file" ]; then
        echo -e "${BLUE}Executing: $(basename "$test_file")${NC}"
        source "$test_file"
    fi
done

# Print summary
print_summary
