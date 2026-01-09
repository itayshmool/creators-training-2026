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
WRENCH="🔧"
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
MAGNIFY="🔍"
BULB="💡"

# Issues found
ISSUES_FOUND=0

# Template repository path (dynamically detected)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_REPO="$(dirname "$SCRIPT_DIR")"

print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_issue() {
    echo -e "${RED}${CROSS} Issue: $1${NC}"
    echo -e "  ${YELLOW}→ $2${NC}"
    ((ISSUES_FOUND++))
}

print_fix() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

ask_fix() {
    echo ""
    read -p "Would you like to fix this now? [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check Node.js
check_node() {
    print_header "${MAGNIFY} Checking Node.js"
    
    if ! command -v node &> /dev/null; then
        print_issue "Node.js not found" "Node.js is required to run this project"
        
        if ask_fix; then
            echo -e "${BLUE}Opening Node.js download page...${NC}"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "https://nodejs.org"
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                xdg-open "https://nodejs.org" 2>/dev/null || echo "Visit: https://nodejs.org"
            fi
            echo -e "${CYAN}After installing, restart your terminal and run this script again.${NC}"
            exit 0
        fi
        return
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_issue "Node.js version too old (v$NODE_VERSION)" "This project requires Node.js 18 or higher"
        
        if ask_fix; then
            echo -e "${BLUE}Opening Node.js download page...${NC}"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "https://nodejs.org"
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                xdg-open "https://nodejs.org" 2>/dev/null || echo "Visit: https://nodejs.org"
            fi
            echo -e "${CYAN}After installing, restart your terminal and run this script again.${NC}"
            exit 0
        fi
    else
        print_fix "Node.js version $(node --version) is good"
    fi
}

# Check dependencies
check_dependencies() {
    print_header "${MAGNIFY} Checking Dependencies"
    
    if [ ! -f "package.json" ]; then
        print_issue "package.json not found" "This doesn't appear to be a Node.js project"
        return
    fi
    
    if [ ! -d "node_modules" ]; then
        print_issue "node_modules/ not found" "Dependencies are not installed"
        
        if ask_fix; then
            echo -e "${BLUE}Installing dependencies...${NC}"
            npm install
            
            if [ $? -eq 0 ]; then
                print_fix "Dependencies installed successfully"
            else
                echo -e "${RED}Failed to install dependencies${NC}"
            fi
        fi
        return
    fi
    
    # Check for missing dependencies
    echo -e "${BLUE}Checking for missing packages...${NC}"
    npm ls &> /dev/null
    
    if [ $? -ne 0 ]; then
        print_issue "Some dependencies are missing or have issues" "npm ls reports problems"
        
        if ask_fix; then
            echo -e "${BLUE}Reinstalling dependencies...${NC}"
            rm -rf node_modules package-lock.json
            npm install
            
            if [ $? -eq 0 ]; then
                print_fix "Dependencies reinstalled successfully"
            else
                echo -e "${RED}Failed to reinstall dependencies${NC}"
            fi
        fi
    else
        print_fix "All dependencies are installed"
    fi
}

# Check cursor rules
check_cursor_rules() {
    print_header "${MAGNIFY} Checking Cursor Rules"
    
    local missing_rules=()
    local essential_rules=(".cursorrules-tdd" ".cursorrules-testing" ".cursorrules-security")
    
    for rule in "${essential_rules[@]}"; do
        if [ ! -f "$rule" ]; then
            missing_rules+=("$rule")
        fi
    done
    
    if [ ${#missing_rules[@]} -gt 0 ]; then
        print_issue "Missing cursor rules: ${missing_rules[*]}" "These rules help Cursor AI understand your project standards"
        
        echo -e "${CYAN}${BULB} Tip: Copy them from the template repository${NC}"
        echo -e "  ${BLUE}$TEMPLATE_REPO/templates/cursorrules/${NC}"
        
        if ask_fix; then
            TEMPLATE_DIR="$TEMPLATE_REPO/templates/cursorrules"
            
            if [ -d "$TEMPLATE_DIR" ]; then
                for rule in "${missing_rules[@]}"; do
                    if [ -f "$TEMPLATE_DIR/$rule" ]; then
                        cp "$TEMPLATE_DIR/$rule" ./
                        echo -e "${GREEN}${CHECK} Copied $rule${NC}"
                    fi
                done
                print_fix "Cursor rules added"
            else
                echo -e "${RED}Template directory not found at $TEMPLATE_DIR${NC}"
                echo -e "${CYAN}Clone the repository with:${NC}"
                echo -e "  ${BLUE}git clone https://github.com/itayshmool/creators-training-2026.git${NC}"
                echo -e "${CYAN}(Run this script from the cloned repository's scripts/ folder)${NC}"
            fi
        fi
    else
        print_fix "All essential cursor rules are present"
    fi
}

# Check TypeScript
check_typescript() {
    print_header "${MAGNIFY} Checking TypeScript"
    
    if [ ! -f "tsconfig.json" ]; then
        echo -e "${YELLOW}${WARNING} No tsconfig.json found (okay if not using TypeScript)${NC}"
        return
    fi
    
    echo -e "${BLUE}Checking TypeScript configuration...${NC}"
    npx tsc --noEmit > /tmp/tsc-check.log 2>&1
    
    if [ $? -ne 0 ]; then
        ERROR_COUNT=$(wc -l < /tmp/tsc-check.log | tr -d ' ')
        print_issue "TypeScript has $ERROR_COUNT error(s)" "Fix these before building"
        
        echo -e "${YELLOW}First few errors:${NC}"
        head -10 /tmp/tsc-check.log
        
        echo ""
        echo -e "${CYAN}${BULB} Tip: Ask Cursor to fix these:${NC}"
        echo -e '  ${BLUE}"Fix all TypeScript errors"${NC}'
    else
        print_fix "TypeScript configuration is valid"
    fi
}

# Check tests
check_tests() {
    print_header "${MAGNIFY} Checking Tests"
    
    # Find test files
    TEST_COUNT=$(find . -name "*.test.ts" -o -name "*.test.js" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$TEST_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}${WARNING} No test files found${NC}"
        echo -e "${CYAN}${BULB} Tip: Start with TDD - write tests first!${NC}"
        return
    fi
    
    echo -e "${BLUE}Found $TEST_COUNT test file(s)${NC}"
    echo -e "${BLUE}Running tests...${NC}"
    
    npm run test:run > /tmp/test-output.log 2>&1
    
    if [ $? -ne 0 ]; then
        print_issue "Some tests are failing" "Fix failing tests before continuing"
        
        echo -e "${YELLOW}Test output:${NC}"
        tail -20 /tmp/test-output.log
        
        echo ""
        echo -e "${CYAN}${BULB} Tip: Ask Cursor to help:${NC}"
        echo -e '  ${BLUE}"Fix the failing tests"${NC}'
    else
        print_fix "All tests passing!"
    fi
}

# Check ports
check_ports() {
    print_header "${MAGNIFY} Checking Ports"
    
    # Common development ports
    PORTS=(3000 5173 8080 4200)
    
    for port in "${PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            PID=$(lsof -Pi :$port -sTCP:LISTEN -t)
            PROCESS=$(ps -p $PID -o comm= 2>/dev/null)
            
            print_issue "Port $port is in use" "Process: $PROCESS (PID: $PID)"
            
            if ask_fix; then
                echo -e "${BLUE}Killing process on port $port...${NC}"
                kill $PID 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    print_fix "Port $port freed"
                else
                    echo -e "${RED}Failed to kill process (might need sudo)${NC}"
                fi
            fi
        fi
    done
    
    if [ $ISSUES_FOUND -eq 0 ]; then
        print_fix "Common development ports are available"
    fi
}

# Check Git
check_git() {
    print_header "${MAGNIFY} Checking Git"
    
    if [ ! -d ".git" ]; then
        print_issue "Not a Git repository" "Git helps track changes"
        
        if ask_fix; then
            echo -e "${BLUE}Initializing Git repository...${NC}"
            git init
            
            if [ $? -eq 0 ]; then
                print_fix "Git repository initialized"
                
                # Create initial commit
                read -p "Create initial commit? [y/N]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    git add .
                    git commit -m "Initial commit"
                    print_fix "Initial commit created"
                fi
            fi
        fi
        return
    fi
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        CHANGES=$(git status --porcelain | wc -l | tr -d ' ')
        echo -e "${YELLOW}${WARNING} $CHANGES uncommitted changes${NC}"
        
        read -p "View changes? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git status
        fi
    else
        print_fix "Working directory is clean"
    fi
}

# Print summary
print_summary() {
    print_header "📊 Summary"
    
    if [ $ISSUES_FOUND -eq 0 ]; then
        echo -e "${GREEN}${CHECK} No issues found!${NC}"
        echo -e "${CYAN}Your project is in good shape.${NC}"
    else
        echo -e "${YELLOW}Found $ISSUES_FOUND issue(s)${NC}"
        echo -e "${CYAN}Review the issues above and fix them for best results.${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}${BULB} Need more help?${NC}"
    echo -e "  ${BLUE}1.${NC} Run verify-project.sh for detailed checks"
    echo -e "  ${BLUE}2.${NC} Ask Cursor AI for assistance"
    echo -e "  ${BLUE}3.${NC} Check docs/DEVELOPMENT-METHODOLOGY.md"
}

# Main execution
main() {
    clear
    
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Project Troubleshooter                                ║
║    Diagnose and fix common issues                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    PROJECT_NAME=$(basename "$(pwd)")
    echo -e "${CYAN}Troubleshooting project: ${PURPLE}$PROJECT_NAME${NC}"
    
    # Run checks
    check_node
    check_dependencies
    check_cursor_rules
    check_typescript
    check_tests
    check_ports
    check_git
    
    # Print summary
    print_summary
}

# Run main function
main

