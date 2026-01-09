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
BROOM="🧹"
TRASH="🗑️"
CHECK="✅"
WARNING="⚠️"
SPARKLE="✨"

# Counter for saved space
TOTAL_SIZE=0

print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ${BROOM} $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

get_size() {
    local path=$1
    if [ -e "$path" ]; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "0K"
    fi
}

get_size_bytes() {
    local path=$1
    if [ -e "$path" ]; then
        du -sk "$path" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

remove_item() {
    local item=$1
    local description=$2
    
    if [ -e "$item" ]; then
        SIZE=$(get_size "$item")
        SIZE_BYTES=$(get_size_bytes "$item")
        
        echo -ne "${BLUE}Removing $description... ${NC}"
        rm -rf "$item" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${CHECK} Freed $SIZE${NC}"
            TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))
        else
            echo -e "${RED}Failed${NC}"
        fi
    else
        echo -e "${YELLOW}${WARNING} $description not found${NC}"
    fi
}

# Clean build outputs
clean_build() {
    print_header "Build Outputs"
    
    remove_item "dist" "dist/"
    remove_item "build" "build/"
    remove_item ".next" ".next/"
    remove_item "out" "out/"
    remove_item ".nuxt" ".nuxt/"
    remove_item ".output" ".output/"
}

# Clean dependencies (with confirmation)
clean_dependencies() {
    print_header "Dependencies"
    
    if [ -d "node_modules" ]; then
        SIZE=$(get_size "node_modules")
        echo -e "${YELLOW}${WARNING} node_modules/ is $SIZE${NC}"
        echo -e "${CYAN}This will need to be reinstalled with: ${YELLOW}npm install${NC}"
        echo ""
        read -p "Remove node_modules? [y/N]: " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            remove_item "node_modules" "node_modules/"
            echo -e "${BLUE}To reinstall: ${YELLOW}npm install${NC}"
        else
            echo -e "${GREEN}Skipped node_modules/${NC}"
        fi
    else
        echo -e "${YELLOW}${WARNING} node_modules/ not found${NC}"
    fi
}

# Clean test coverage
clean_coverage() {
    print_header "Test Coverage"
    
    remove_item "coverage" "coverage/"
    remove_item ".vitest" ".vitest/"
    remove_item ".nyc_output" ".nyc_output/"
    remove_item ".jest" ".jest/"
}

# Clean caches
clean_caches() {
    print_header "Caches"
    
    remove_item ".cache" ".cache/"
    remove_item ".parcel-cache" ".parcel-cache/"
    remove_item ".turbo" ".turbo/"
    remove_item ".vite" ".vite/"
    remove_item ".swc" ".swc/"
    remove_item ".webpack" ".webpack/"
}

# Clean temp files
clean_temp() {
    print_header "Temporary Files"
    
    remove_item "tmp" "tmp/"
    remove_item "temp" "temp/"
    remove_item ".tmp" ".tmp/"
    
    # Remove log files
    echo -e "${BLUE}Removing log files...${NC}"
    find . -name "*.log" -type f -delete 2>/dev/null
    find . -name "npm-debug.log*" -type f -delete 2>/dev/null
    find . -name "yarn-debug.log*" -type f -delete 2>/dev/null
    find . -name "yarn-error.log*" -type f -delete 2>/dev/null
    echo -e "${GREEN}${CHECK} Log files removed${NC}"
    
    # Remove OS files
    echo -e "${BLUE}Removing OS files...${NC}"
    find . -name ".DS_Store" -type f -delete 2>/dev/null
    find . -name "Thumbs.db" -type f -delete 2>/dev/null
    echo -e "${GREEN}${CHECK} OS files removed${NC}"
}

# Print summary
print_summary() {
    print_header "${SPARKLE} Cleanup Complete!"
    
    # Convert KB to human readable
    if [ $TOTAL_SIZE -gt 1048576 ]; then
        # GB
        SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)
        SIZE_STR="${SIZE_GB}GB"
    elif [ $TOTAL_SIZE -gt 1024 ]; then
        # MB
        SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024" | bc)
        SIZE_STR="${SIZE_MB}MB"
    else
        # KB
        SIZE_STR="${TOTAL_SIZE}KB"
    fi
    
    echo -e "${GREEN}Total space freed: ${PURPLE}$SIZE_STR${NC}"
    echo ""
    
    if [ -d "node_modules" ]; then
        echo -e "${CYAN}${CHECK} Project ready to use${NC}"
    else
        echo -e "${YELLOW}${WARNING} Remember to reinstall dependencies:${NC}"
        echo -e "  ${BLUE}npm install${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}${SPARKLE} Your project is clean!${NC}"
}

# Quick clean (no confirmations)
quick_clean() {
    print_header "Quick Clean"
    echo -e "${CYAN}Removing build outputs, coverage, and caches...${NC}"
    echo ""
    
    clean_build
    clean_coverage
    clean_caches
    clean_temp
    
    print_summary
}

# Full clean (with confirmations)
full_clean() {
    clean_build
    clean_dependencies
    clean_coverage
    clean_caches
    clean_temp
    
    print_summary
}

# Main execution
main() {
    clear
    
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Project Cleanup                                       ║
║    Free up disk space                                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    PROJECT_NAME=$(basename "$(pwd)")
    echo -e "${CYAN}Cleaning project: ${PURPLE}$PROJECT_NAME${NC}"
    echo ""
    
    echo -e "${CYAN}What would you like to clean?${NC}"
    echo ""
    echo -e "  ${BLUE}1.${NC} Quick clean (build outputs, coverage, caches)"
    echo -e "  ${BLUE}2.${NC} Full clean (includes node_modules - requires reinstall)"
    echo -e "  ${BLUE}3.${NC} Cancel"
    echo ""
    read -p "Choose an option [1-3]: " -n 1 -r
    echo ""
    echo ""
    
    case $REPLY in
        1)
            quick_clean
            ;;
        2)
            full_clean
            ;;
        3)
            echo -e "${YELLOW}Cleanup cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
}

# Run main function
main

