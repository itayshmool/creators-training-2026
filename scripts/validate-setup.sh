#!/bin/bash

# CDD Workshop - Validation Script
# Run this to verify your development environment is ready

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_check() {
    echo -e "${BLUE}Checking:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
}

clear
echo "=================================="
echo "CDD Workshop - Environment Check"
echo "=================================="
echo ""

all_good=1

# Check Node.js
print_check "Node.js"
if command -v node &> /dev/null; then
    print_success "Node.js $(node --version)"
else
    print_fail "Node.js not found"
    all_good=0
fi
echo ""

# Check npm
print_check "npm"
if command -v npm &> /dev/null; then
    print_success "npm v$(npm --version)"
else
    print_fail "npm not found"
    all_good=0
fi
echo ""

# Check Python
print_check "Python 3"
if command -v python3 &> /dev/null; then
    print_success "$(python3 --version)"
else
    print_fail "Python 3 not found"
    all_good=0
fi
echo ""

# Check Git
print_check "Git"
if command -v git &> /dev/null; then
    print_success "$(git --version)"
else
    print_fail "Git not found"
    all_good=0
fi
echo ""

# Check Homebrew
print_check "Homebrew"
if command -v brew &> /dev/null; then
    print_success "$(brew --version | head -n 1)"
else
    print_fail "Homebrew not found"
    all_good=0
fi
echo ""

# Final verdict
echo "=================================="
if [ $all_good -eq 1 ]; then
    print_success "All tools ready! You're set for the workshop! 🎉"
else
    print_fail "Some tools are missing. Please run setup-mac.sh"
fi
echo "=================================="
echo ""
