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
ROCKET="🚀"
CHECK="✅"
CROSS="❌"
GEAR="⚙️"

print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${GEAR} $1${NC}"
}

main() {
    clear
    
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Install Helper Scripts                                ║
║    Make scripts available globally                       ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    print_header "Installing Scripts"
    
    # Determine install directory
    INSTALL_DIR="$HOME/bin"
    
    # Create directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "Creating $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
    
    # List of scripts to install
    SCRIPTS=(
        "setup-new-project.sh"
        "verify-project.sh"
        "cleanup-project.sh"
        "troubleshoot.sh"
    )
    
    # Install each script
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then
            print_info "Installing $script"
            
            # Make executable
            chmod +x "$script"
            
            # Copy to install directory
            cp "$script" "$INSTALL_DIR/"
            
            if [ $? -eq 0 ]; then
                print_success "$script installed"
            else
                print_error "Failed to install $script"
            fi
        else
            print_error "$script not found"
        fi
    done
    
    print_header "Setting Up PATH"
    
    # Check if install directory is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_info "Adding $INSTALL_DIR to PATH"
        
        # Determine shell config file
        SHELL_CONFIG=""
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        
        if [ -n "$SHELL_CONFIG" ]; then
            # Add to shell config if not already there
            if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$SHELL_CONFIG" 2>/dev/null; then
                echo "" >> "$SHELL_CONFIG"
                echo "# Helper scripts" >> "$SHELL_CONFIG"
                echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$SHELL_CONFIG"
                print_success "Added to $SHELL_CONFIG"
                
                echo ""
                echo -e "${YELLOW}⚠️  To use the scripts immediately, run:${NC}"
                echo -e "  ${BLUE}source $SHELL_CONFIG${NC}"
                echo ""
                echo -e "${YELLOW}Or restart your terminal.${NC}"
            else
                print_success "PATH already configured"
            fi
        else
            print_error "Could not determine shell config file"
            echo ""
            echo -e "${YELLOW}Add this line to your shell config manually:${NC}"
            echo -e "  ${BLUE}export PATH=\"\$HOME/bin:\$PATH\"${NC}"
        fi
    else
        print_success "$INSTALL_DIR is already in PATH"
    fi
    
    print_header "${ROCKET} Installation Complete!"
    
    echo -e "${GREEN}Scripts installed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Available commands:${NC}"
    echo ""
    echo -e "  ${BLUE}setup-new-project.sh${NC}    ${YELLOW}Create a new project${NC}"
    echo -e "  ${BLUE}verify-project.sh${NC}       ${YELLOW}Verify project setup${NC}"
    echo -e "  ${BLUE}cleanup-project.sh${NC}      ${YELLOW}Clean build files${NC}"
    echo -e "  ${BLUE}troubleshoot.sh${NC}         ${YELLOW}Diagnose issues${NC}"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  ${BLUE}setup-new-project.sh my-new-project${NC}"
    echo -e "  ${BLUE}verify-project.sh${NC}  ${YELLOW}(run from project directory)${NC}"
    echo ""
    echo -e "${GREEN}${ROCKET} Happy coding!${NC}"
}

main

