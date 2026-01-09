#!/bin/bash

# CDD Workshop - Mac Development Environment Setup Script
# This script installs all required development tools for the workshop

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Welcome message
clear
echo "=================================="
echo "CDD Workshop - Mac Setup Script"
echo "=================================="
echo ""
echo "This script will install:"
echo "  • Xcode Command Line Tools"
echo "  • Homebrew (package manager)"
echo "  • Node.js v20 (includes npm)"
echo "  • Python 3"
echo "  • Git"
echo ""
echo "Tools already installed will be skipped."
echo "This will take 10-15 minutes."
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Check macOS version
print_step "Checking macOS version..."
os_version=$(sw_vers -productVersion)
major_version=$(echo "$os_version" | cut -d '.' -f 1)

if [ "$major_version" -lt 11 ]; then
    print_error "macOS version $os_version detected. Requires macOS 11 (Big Sur) or newer."
    exit 1
fi
print_success "macOS $os_version detected"
echo ""

# Check for admin privileges (required for Homebrew and other installations)
print_step "Checking for administrator privileges..."

# Check if user is in admin group
current_user=$(whoami)
if groups "$current_user" | grep -qE '\badmin\b'; then
    print_success "User '$current_user' has administrator privileges"
else
    print_error "Administrator privileges required!"
    echo ""
    echo "Your user account ($current_user) is not an administrator on this Mac."
    echo "This is required to install Homebrew and other development tools."
    echo ""
    echo "To fix this, ask an administrator to:"
    echo "  1. Open System Settings (or System Preferences)"
    echo "  2. Go to Users & Groups"
    echo "  3. Click on your user account ($current_user)"
    echo "  4. Enable 'Allow user to administer this computer'"
    echo ""
    echo "After getting admin access, please run this script again."
    echo ""
    exit 1
fi
echo ""

# Install Xcode Command Line Tools
print_step "Checking for Xcode Command Line Tools..."
if xcode-select -p &> /dev/null; then
    print_success "Xcode Command Line Tools already installed"
else
    print_warning "Xcode Command Line Tools not found. Installing..."
    echo "A popup will appear - click 'Install' and wait for completion."
    xcode-select --install
    echo "Waiting for Xcode Command Line Tools installation..."
    echo "This may take 5-10 minutes. Please wait..."
    
    # Wait for installation to complete
    until xcode-select -p &> /dev/null; do
        sleep 5
    done
    
    print_success "Xcode Command Line Tools installed"
fi
echo ""

# Install Homebrew
print_step "Checking for Homebrew..."
if command -v brew &> /dev/null; then
    print_success "Homebrew already installed ($(brew --version | head -n 1))"
else
    print_warning "Homebrew not found. Installing..."
    
    # Set NONINTERACTIVE to avoid TTY issues when script is piped
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed"
fi
echo ""

# Update Homebrew
print_step "Updating Homebrew..."
brew update &> /dev/null
print_success "Homebrew updated"
echo ""

# Install Node.js
print_step "Checking for Node.js..."
if command -v node &> /dev/null; then
    node_version=$(node --version)
    print_success "Node.js already installed ($node_version)"
else
    print_warning "Node.js not found. Installing Node.js v20..."
    brew install node@20
    
    # Link node@20
    brew link node@20
    
    print_success "Node.js installed ($(node --version))"
fi
echo ""

# Verify npm
print_step "Checking for npm..."
if command -v npm &> /dev/null; then
    npm_version=$(npm --version)
    print_success "npm already installed (v$npm_version)"
else
    print_error "npm not found (should come with Node.js)"
    exit 1
fi
echo ""

# Install Python 3
print_step "Checking for Python 3..."
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    print_success "Python 3 already installed ($python_version)"
else
    print_warning "Python 3 not found. Installing..."
    brew install python@3.12
    print_success "Python 3 installed ($(python3 --version))"
fi
echo ""

# Install/verify Git
print_step "Checking for Git..."
if command -v git &> /dev/null; then
    git_version=$(git --version)
    print_success "Git already installed ($git_version)"
else
    print_warning "Git not found. Installing..."
    brew install git
    print_success "Git installed ($(git --version))"
fi
echo ""

# Validation
echo "=================================="
echo "Validation"
echo "=================================="
echo ""

validation_failed=0

# Validate Node.js
print_step "Validating Node.js..."
if command -v node &> /dev/null; then
    node_version=$(node --version)
    print_success "Node.js $node_version"
else
    print_error "Node.js validation failed"
    validation_failed=1
fi

# Validate npm
print_step "Validating npm..."
if command -v npm &> /dev/null; then
    npm_version=$(npm --version)
    print_success "npm v$npm_version"
else
    print_error "npm validation failed"
    validation_failed=1
fi

# Validate Python
print_step "Validating Python 3..."
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    print_success "$python_version"
else
    print_error "Python 3 validation failed"
    validation_failed=1
fi

# Validate Git
print_step "Validating Git..."
if command -v git &> /dev/null; then
    git_version=$(git --version)
    print_success "$git_version"
else
    print_error "Git validation failed"
    validation_failed=1
fi

# Validate Homebrew
print_step "Validating Homebrew..."
if command -v brew &> /dev/null; then
    brew_version=$(brew --version | head -n 1)
    print_success "$brew_version"
else
    print_error "Homebrew validation failed"
    validation_failed=1
fi

echo ""

# Final result
if [ $validation_failed -eq 0 ]; then
    echo "=================================="
    print_success "Setup Complete!"
    echo "=================================="
    echo ""
    echo "All tools installed and validated."
    echo ""
    echo "⚠️  IMPORTANT: Please close this Terminal window and open a new one"
    echo "   to ensure all tools are properly loaded."
    echo ""
    echo "You're ready for the workshop! 🎉"
else
    echo "=================================="
    print_error "Setup Incomplete"
    echo "=================================="
    echo ""
    echo "Some tools failed validation."
    echo "Please screenshot this output and email it to us."
    echo ""
    echo "We'll help you get set up before the workshop."
fi

echo ""
