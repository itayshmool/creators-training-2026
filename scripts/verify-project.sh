#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
MAGNIFY="🔍"

# Counters
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ${MAGNIFY} $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}${CHECK} $1${NC}"
    ((PASSED_CHECKS++))
}

check_fail() {
    echo -e "${RED}${CROSS} $1${NC}"
    if [ -n "$2" ]; then
        echo -e "  ${YELLOW}→ $2${NC}"
    fi
    ((FAILED_CHECKS++))
}

check_warn() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
    if [ -n "$2" ]; then
        echo -e "  ${CYAN}→ $2${NC}"
    fi
    ((WARNING_CHECKS++))
}

check_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

# Check system tools
check_tools() {
    print_header "System Tools"
    
    # Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        check_pass "Node.js: $NODE_VERSION"
    else
        check_fail "Node.js not found" "Install from https://nodejs.org"
    fi
    
    # npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        check_pass "npm: $NPM_VERSION"
    else
        check_fail "npm not found" "Comes with Node.js"
    fi
    
    # Git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | cut -d ' ' -f 3)
        check_pass "Git: $GIT_VERSION"
    else
        check_fail "Git not found" "Install from https://git-scm.com"
    fi
    
    # TypeScript
    if npm list -g typescript &> /dev/null || npm list typescript &> /dev/null; then
        check_pass "TypeScript installed"
    else
        check_warn "TypeScript not found" "Will install with project"
    fi
}

# Check cursor rules
check_cursor_rules() {
    print_header "Cursor Rules"
    
    local rules_found=0
    local essential_rules=(".cursorrules-tdd" ".cursorrules-testing" ".cursorrules-security")
    local optional_rules=(".cursorrules-architecture" ".cursorrules-performance")
    
    # Essential rules
    for rule in "${essential_rules[@]}"; do
        if [ -f "$rule" ]; then
            check_pass "Essential: $rule"
            ((rules_found++))
        else
            check_fail "Missing: $rule" "Copy from templates/cursorrules/"
        fi
    done
    
    # Optional rules
    for rule in "${optional_rules[@]}"; do
        if [ -f "$rule" ]; then
            check_pass "Optional: $rule"
        else
            check_info "Optional: $rule (not required)"
        fi
    done
    
    if [ $rules_found -eq ${#essential_rules[@]} ]; then
        check_pass "All essential cursor rules present"
    fi
}

# Check project structure
check_structure() {
    print_header "Project Structure"
    
    # Essential directories
    if [ -d "src" ]; then
        check_pass "src/ directory exists"
    else
        check_fail "src/ directory missing" "Create with: mkdir src"
    fi
    
    if [ -d "tests" ] || [ -d "test" ] || [ -d "__tests__" ]; then
        check_pass "Test directory exists"
    else
        check_warn "No test directory found" "Create with: mkdir tests"
    fi
    
    # Documentation
    if [ -d "docs" ]; then
        check_pass "docs/ directory exists"
        
        if [ -f "docs/DEVELOPMENT-METHODOLOGY.md" ]; then
            check_pass "Methodology documentation present"
        else
            check_warn "Methodology documentation missing" "Copy from template"
        fi
    else
        check_warn "docs/ directory missing" "Create with: mkdir docs"
    fi
    
    # README
    if [ -f "README.md" ]; then
        check_pass "README.md exists"
    else
        check_fail "README.md missing" "Every project needs a README"
    fi
}

# Check dependencies
check_dependencies() {
    print_header "Dependencies"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        check_fail "node_modules/ not found" "Run: npm install"
        return
    fi
    
    # Check package.json
    if [ ! -f "package.json" ]; then
        check_fail "package.json not found" "Run: npm init"
        return
    fi
    
    check_pass "node_modules/ exists"
    
    # Check key dependencies
    if npm list vitest &> /dev/null; then
        check_pass "Vitest installed"
    else
        check_fail "Vitest not installed" "Run: npm install -D vitest"
    fi
    
    if npm list typescript &> /dev/null; then
        check_pass "TypeScript installed"
    else
        check_fail "TypeScript not installed" "Run: npm install -D typescript"
    fi
    
    # Check for outdated packages
    OUTDATED=$(npm outdated 2>/dev/null | wc -l)
    if [ "$OUTDATED" -gt 1 ]; then
        check_warn "$((OUTDATED - 1)) outdated packages" "Run: npm update"
    else
        check_pass "All packages up to date"
    fi
}

# Check configurations
check_configs() {
    print_header "Configuration Files"
    
    # TypeScript config
    if [ -f "tsconfig.json" ]; then
        check_pass "tsconfig.json exists"
        
        # Try to validate it
        if npx tsc --noEmit > /dev/null 2>&1; then
            check_pass "TypeScript config is valid"
        else
            check_fail "TypeScript config has errors" "Run: npx tsc --noEmit"
        fi
    else
        check_warn "tsconfig.json missing" "Create TypeScript config"
    fi
    
    # Vitest config
    if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
        check_pass "Vitest config exists"
    else
        check_warn "Vitest config missing" "Create vitest.config.ts"
    fi
    
    # .gitignore
    if [ -f ".gitignore" ]; then
        check_pass ".gitignore exists"
        
        # Check if it contains common entries
        if grep -q "node_modules" .gitignore; then
            check_pass ".gitignore has node_modules"
        else
            check_warn ".gitignore missing node_modules" "Add common ignore patterns"
        fi
    else
        check_warn ".gitignore missing" "Create to avoid committing unwanted files"
    fi
    
    # package.json scripts
    if [ -f "package.json" ]; then
        if grep -q '"test"' package.json; then
            check_pass "Test script configured"
        else
            check_fail "No test script in package.json" "Add: \"test\": \"vitest\""
        fi
    fi
}

# Check Git
check_git() {
    print_header "Git Repository"
    
    if [ ! -d ".git" ]; then
        check_fail "Not a Git repository" "Run: git init"
        return
    fi
    
    check_pass "Git repository initialized"
    
    # Check for commits
    COMMIT_COUNT=$(git rev-list --all --count 2>/dev/null || echo "0")
    if [ "$COMMIT_COUNT" -gt 0 ]; then
        check_pass "$COMMIT_COUNT commits in repository"
    else
        check_warn "No commits yet" "Create initial commit"
    fi
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        CHANGES=$(git status --porcelain | wc -l | tr -d ' ')
        check_warn "$CHANGES uncommitted changes" "Review with: git status"
    else
        check_pass "Working directory clean"
    fi
    
    # Check for remote
    if git remote -v | grep -q "origin"; then
        REMOTE=$(git remote get-url origin 2>/dev/null)
        check_pass "Remote configured: $REMOTE"
    else
        check_info "No remote configured (okay for local projects)"
    fi
}

# Check tests
check_tests() {
    print_header "Testing Setup"
    
    # Find test files
    TEST_FILES=$(find . -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$TEST_FILES" -gt 0 ]; then
        check_pass "Found $TEST_FILES test file(s)"
        
        # Try to run tests
        if npm run test:run &> /dev/null || npm test -- run &> /dev/null; then
            check_pass "Tests can run"
            
            # Check coverage
            if [ -f "coverage/coverage-summary.json" ]; then
                COVERAGE=$(cat coverage/coverage-summary.json | grep -o '"lines":{"total":[0-9]*,"covered":[0-9]*' | head -1 | sed 's/.*"covered":\([0-9]*\)/\1/')
                TOTAL=$(cat coverage/coverage-summary.json | grep -o '"lines":{"total":[0-9]*' | head -1 | sed 's/.*"total":\([0-9]*\)/\1/')
                
                if [ -n "$COVERAGE" ] && [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
                    PERCENT=$((COVERAGE * 100 / TOTAL))
                    if [ "$PERCENT" -ge 70 ]; then
                        check_pass "Coverage: ${PERCENT}% (above 70% threshold)"
                    else
                        check_warn "Coverage: ${PERCENT}% (below 70% threshold)" "Add more tests"
                    fi
                fi
            else
                check_info "No coverage report (run: npm run test:coverage)"
            fi
        else
            check_warn "Tests exist but some may be failing" "Run: npm test"
        fi
    else
        check_warn "No test files found" "Start with TDD: write tests first"
    fi
}

# Print summary
print_summary() {
    print_header "📊 Verification Summary"
    
    TOTAL_CHECKS=$((PASSED_CHECKS + FAILED_CHECKS + WARNING_CHECKS))
    SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    echo -e "${CYAN}Results:${NC}"
    echo -e "  ${GREEN}${CHECK} Passed:   $PASSED_CHECKS${NC}"
    echo -e "  ${RED}${CROSS} Failed:   $FAILED_CHECKS${NC}"
    echo -e "  ${YELLOW}${WARNING} Warnings: $WARNING_CHECKS${NC}"
    echo ""
    echo -e "${CYAN}Score: ${PURPLE}$SCORE%${NC}"
    echo ""
    
    # Verdict
    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 Perfect! Your project is fully set up!${NC}"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✨ Great! Some minor improvements possible.${NC}"
    elif [ $FAILED_CHECKS -le 2 ]; then
        echo -e "${YELLOW}⚠️  Almost there! Fix the failed checks above.${NC}"
    else
        echo -e "${RED}❌ Setup incomplete. Please address the issues above.${NC}"
    fi
    
    echo ""
    
    # Suggested next steps
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo -e "${CYAN}🔧 Suggested Fixes:${NC}"
        echo ""
        
        if ! command -v node &> /dev/null; then
            echo -e "  ${BLUE}1.${NC} Install Node.js: ${YELLOW}https://nodejs.org${NC}"
        fi
        
        if [ ! -f ".cursorrules-tdd" ]; then
            echo -e "  ${BLUE}2.${NC} Copy cursor rules from template repository"
        fi
        
        if [ ! -d "node_modules" ]; then
            echo -e "  ${BLUE}3.${NC} Install dependencies: ${YELLOW}npm install${NC}"
        fi
        
        if [ ! -d ".git" ]; then
            echo -e "  ${BLUE}4.${NC} Initialize Git: ${YELLOW}git init${NC}"
        fi
        
        echo ""
    fi
}

# Main execution
main() {
    clear
    
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Project Setup Verification                            ║
║    Checking your development environment                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Get current directory name
    PROJECT_NAME=$(basename "$(pwd)")
    echo -e "${CYAN}Verifying project: ${PURPLE}$PROJECT_NAME${NC}"
    echo -e "${CYAN}Location: ${BLUE}$(pwd)${NC}"
    
    # Run checks
    check_tools
    check_cursor_rules
    check_structure
    check_dependencies
    check_configs
    check_git
    check_tests
    
    # Print summary
    print_summary
}

# Run main function
main

