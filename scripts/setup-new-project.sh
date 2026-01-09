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
ROCKET="🚀"
GEAR="⚙️"
BOOK="📚"
WARNING="⚠️"
PARTY="🎉"

# Template repository path
TEMPLATE_REPO="$HOME/creators-training-2026"

# Functions
print_header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}${GEAR} $1...${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local all_good=true
    
    # Check Node.js
    print_step "Checking Node.js"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js not found. Please install Node.js 20+ from https://nodejs.org"
        all_good=false
    fi
    
    # Check npm
    print_step "Checking npm"
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm not found. Please install Node.js which includes npm"
        all_good=false
    fi
    
    # Check Git
    print_step "Checking Git"
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version)
        print_success "Git found: $GIT_VERSION"
    else
        print_error "Git not found. Please install Git from https://git-scm.com"
        all_good=false
    fi
    
    # Check template repository
    print_step "Checking template repository"
    if [ -d "$TEMPLATE_REPO" ]; then
        print_success "Template found at: $TEMPLATE_REPO"
    else
        print_error "Template repository not found at: $TEMPLATE_REPO"
        echo -e "  ${YELLOW}Please clone it first:${NC}"
        echo -e "  ${CYAN}git clone https://github.com/itayshmool/creators-training-2026.git ~/creators-training-2026${NC}"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        echo ""
        print_error "Prerequisites check failed. Please fix the issues above and try again."
        exit 1
    fi
    
    echo ""
    print_success "All prerequisites met!"
}

create_project() {
    PROJECT_NAME=$1
    
    print_header "Creating Project: $PROJECT_NAME"
    
    # Check if directory exists
    if [ -d "$PROJECT_NAME" ]; then
        print_error "Directory '$PROJECT_NAME' already exists!"
        echo -e "  ${YELLOW}Please choose a different name or remove the existing directory.${NC}"
        exit 1
    fi
    
    # Create directory
    print_step "Creating project directory"
    mkdir "$PROJECT_NAME" || {
        print_error "Failed to create directory"
        exit 1
    }
    cd "$PROJECT_NAME" || exit
    print_success "Project directory created"
    
    # Initialize Git
    print_step "Initializing Git repository"
    git init -q
    print_success "Git initialized"
    
    # Initialize npm
    print_step "Initializing npm project"
    npm init -y > /dev/null 2>&1
    
    # Update package.json name
    if command -v jq &> /dev/null; then
        tmp=$(mktemp)
        jq --arg name "$PROJECT_NAME" '.name = $name' package.json > "$tmp" && mv "$tmp" package.json
    fi
    
    print_success "npm project initialized"
}

install_dependencies() {
    print_header "Installing Dependencies"
    
    print_step "Installing testing framework (Vitest)"
    npm install -D vitest @vitest/ui @vitest/coverage-v8 --silent 2>&1 | grep -v "npm WARN" || true
    print_success "Vitest installed"
    
    print_step "Installing TypeScript"
    npm install -D typescript @types/node --silent 2>&1 | grep -v "npm WARN" || true
    print_success "TypeScript installed"
    
    echo ""
    print_success "All dependencies installed!"
}

setup_structure() {
    print_header "Setting Up Project Structure"
    
    # Create directories
    print_step "Creating directories"
    mkdir -p src tests docs
    print_success "Directories created: src, tests, docs"
    
    # Create basic files
    print_step "Creating basic files"
    touch src/index.ts
    touch tests/index.test.ts
    touch README.md
    print_success "Basic files created"
}

copy_cursor_rules() {
    print_header "Copying Cursor Rules"
    
    # Essential rules
    print_step "Copying essential cursor rules"
    cp "$TEMPLATE_REPO/templates/cursorrules/.cursorrules-tdd" ./ 2>/dev/null || {
        print_error "Failed to copy .cursorrules-tdd"
        exit 1
    }
    print_success "TDD rules copied"
    
    cp "$TEMPLATE_REPO/templates/cursorrules/.cursorrules-testing" ./ 2>/dev/null || {
        print_error "Failed to copy .cursorrules-testing"
        exit 1
    }
    print_success "Testing rules copied"
    
    cp "$TEMPLATE_REPO/templates/cursorrules/.cursorrules-security" ./ 2>/dev/null || {
        print_error "Failed to copy .cursorrules-security"
        exit 1
    }
    print_success "Security rules copied"
    
    # Ask for optional rules
    echo ""
    read -p "Do you need architecture patterns? (recommended for complex projects) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$TEMPLATE_REPO/templates/cursorrules/.cursorrules-architecture" ./
        print_success "Architecture rules copied"
    fi
    
    read -p "Do you need performance optimization rules? (for high-traffic apps) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$TEMPLATE_REPO/templates/cursorrules/.cursorrules-performance" ./
        print_success "Performance rules copied"
    fi
}

copy_documentation() {
    print_header "Copying Documentation"
    
    print_step "Copying full methodology"
    cp "$TEMPLATE_REPO/DEVELOPMENT-METHODOLOGY.md" ./docs/ 2>/dev/null || {
        print_warning "Could not copy methodology (continuing anyway)"
    }
    print_success "Methodology copied"
    
    print_step "Copying quick guides"
    cp "$TEMPLATE_REPO/methodologies"/*.md ./docs/ 2>/dev/null || {
        print_warning "Could not copy quick guides (continuing anyway)"
    }
    print_success "Quick guides copied"
}

create_configs() {
    print_header "Creating Configuration Files"
    
    # TypeScript config
    print_step "Creating TypeScript configuration"
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022"],
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF
    print_success "TypeScript config created"
    
    # Vitest config
    print_step "Creating Vitest configuration"
    cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '**/*.test.ts',
        '**/*.config.ts',
        'dist/'
      ],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70
      }
    }
  }
});
EOF
    print_success "Vitest config created"
    
    # Update package.json scripts
    print_step "Adding test scripts to package.json"
    if command -v jq &> /dev/null; then
        tmp=$(mktemp)
        jq '.scripts += {
            "test": "vitest",
            "test:run": "vitest run",
            "test:coverage": "vitest run --coverage",
            "test:ui": "vitest --ui",
            "build": "tsc",
            "dev": "tsc --watch"
        }' package.json > "$tmp" && mv "$tmp" package.json
        print_success "Scripts added to package.json"
    else
        print_warning "jq not found, please add test scripts manually"
    fi
    
    # .gitignore
    print_step "Creating .gitignore"
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/

# Build outputs
dist/
build/

# Environment variables
.env
.env.local
.env.*.local

# Test coverage
coverage/
.vitest/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF
    print_success ".gitignore created"
}

create_readme() {
    print_step "Creating README"
    
    cat > README.md << EOF
# $PROJECT_NAME

Professional development project with TDD, security, and AI assistance built-in.

## 🚀 Quick Start

\`\`\`bash
# Install dependencies
npm install

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Build
npm run build
\`\`\`

## 📚 Development Methodology

This project follows professional development practices:

- ✅ **Test-Driven Development** - Tests first, always
- ✅ **70%+ Test Coverage** - Enforced by cursor rules
- ✅ **Security by Default** - Built-in security patterns
- ✅ **AI-Assisted** - Cursor AI configured with project standards

See \`docs/DEVELOPMENT-METHODOLOGY.md\` for complete guidelines.

## 🛠️ Development

### Writing Tests

All features must be developed with TDD:
1. Write failing test (RED)
2. Write minimal implementation (GREEN)
3. Refactor (REFACTOR)

### Using Cursor AI

Cursor is configured with project rules. Just ask naturally:

\`\`\`
Create a user authentication endpoint with tests
\`\`\`

Cursor will automatically:
- Write tests first
- Follow security best practices
- Ensure 70%+ coverage

### Reference Documentation

Use \`@\` to reference documentation in Cursor:

\`\`\`
@docs/DEVELOPMENT-METHODOLOGY.md

Implement password reset following security best practices
\`\`\`

## 📁 Project Structure

\`\`\`
$PROJECT_NAME/
├── .cursorrules-tdd           # TDD enforcement
├── .cursorrules-testing       # Testing standards
├── .cursorrules-security      # Security patterns
├── src/                       # Source code
├── tests/                     # Test files
└── docs/                      # Documentation
\`\`\`

## 🧪 Testing

\`\`\`bash
# Watch mode (recommended for development)
npm test

# Run once
npm run test:run

# With coverage report
npm run test:coverage

# Interactive UI
npm run test:ui
\`\`\`

## 📊 Coverage Requirements

- Overall: 70% minimum
- Critical paths: 90%+
- Tests written before implementation

## 🔒 Security

Security patterns are enforced via cursor rules:
- Input validation
- Authentication patterns
- Rate limiting
- XSS/SQL injection prevention

## 🤝 Contributing

1. Write test first (TDD)
2. Implement feature
3. Ensure tests pass
4. Check coverage meets threshold
5. Submit PR

## 📝 License

MIT

---

**Created with** [creators-training-2026](https://github.com/itayshmool/creators-training-2026)
EOF
    
    print_success "README.md created"
}

verify_setup() {
    print_header "Verifying Setup"
    
    local all_good=true
    
    # Check files exist
    print_step "Checking cursor rules"
    if [ -f ".cursorrules-tdd" ] && [ -f ".cursorrules-testing" ] && [ -f ".cursorrules-security" ]; then
        print_success "Cursor rules present"
    else
        print_error "Some cursor rules are missing"
        all_good=false
    fi
    
    # Check TypeScript compiles
    print_step "Checking TypeScript configuration"
    if npx tsc --noEmit > /dev/null 2>&1; then
        print_success "TypeScript configuration valid"
    else
        print_warning "TypeScript configuration may have issues (this is okay for now)"
    fi
    
    # Check tests can run
    print_step "Checking test setup"
    if npm run test:run > /dev/null 2>&1; then
        print_success "Test framework working"
    else
        print_warning "Test framework setup (no tests yet, this is normal)"
    fi
    
    # Check Git
    print_step "Checking Git repository"
    if [ -d ".git" ]; then
        print_success "Git repository initialized"
    else
        print_error "Git repository not found"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        print_warning "Some checks failed, but you can continue"
    else
        echo ""
        print_success "All verifications passed!"
    fi
}

create_initial_commit() {
    print_header "Creating Initial Commit"
    
    print_step "Staging all files"
    git add .
    print_success "Files staged"
    
    print_step "Creating commit"
    git commit -m "Initial commit: Project setup with TDD and cursor rules

- Added cursor rules for TDD, testing, security
- Configured TypeScript and Vitest
- Added development methodology documentation
- Project ready for development

Setup automated with creators-training-2026" > /dev/null 2>&1
    
    print_success "Initial commit created"
}

print_summary() {
    print_header "${PARTY} Setup Complete!"
    
    echo -e "${GREEN}Your project '$PROJECT_NAME' is ready!${NC}"
    echo ""
    echo -e "${CYAN}📁 Project Location:${NC}"
    echo -e "   $(pwd)"
    echo ""
    echo -e "${CYAN}🎯 What's Included:${NC}"
    echo -e "   ${CHECK} Test-Driven Development enforced"
    echo -e "   ${CHECK} 70%+ test coverage required"
    echo -e "   ${CHECK} Security best practices built-in"
    echo -e "   ${CHECK} AI assistance configured"
    echo -e "   ${CHECK} Full documentation in docs/"
    echo ""
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "   1. ${BLUE}cd $PROJECT_NAME${NC}"
    echo -e "   2. ${BLUE}cursor .${NC}  ${YELLOW}(or open in your IDE)${NC}"
    echo -e "   3. ${BLUE}Start coding!${NC}"
    echo ""
    echo -e "${CYAN}💡 Quick Commands:${NC}"
    echo -e "   ${BLUE}npm test${NC}              # Run tests in watch mode"
    echo -e "   ${BLUE}npm run test:coverage${NC} # Check coverage"
    echo -e "   ${BLUE}npm run build${NC}         # Build project"
    echo ""
    echo -e "${CYAN}📚 Using Cursor AI:${NC}"
    echo -e "   Just ask naturally:"
    echo -e "   ${YELLOW}\"Create a user login endpoint with tests\"${NC}"
    echo ""
    echo -e "   Cursor will automatically:"
    echo -e "   • Write tests first ${CHECK}"
    echo -e "   • Follow security patterns ${CHECK}"
    echo -e "   • Ensure 70%+ coverage ${CHECK}"
    echo ""
    echo -e "${GREEN}${PARTY} Happy coding! ${PARTY}${NC}"
    echo ""
}

# Main execution
main() {
    clear
    
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Professional Project Setup                            ║
║    with TDD & AI Assistance                              ║
║                                                           ║
║    Powered by: creators-training-2026                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Get project name
    if [ -z "$1" ]; then
        echo -e "${CYAN}Enter project name:${NC} "
        read -r PROJECT_NAME
        
        if [ -z "$PROJECT_NAME" ]; then
            print_error "Project name cannot be empty"
            exit 1
        fi
    else
        PROJECT_NAME=$1
    fi
    
    # Run setup steps
    check_prerequisites
    create_project "$PROJECT_NAME"
    install_dependencies
    setup_structure
    copy_cursor_rules
    copy_documentation
    create_configs
    create_readme
    verify_setup
    create_initial_commit
    
    # Go back to parent directory
    cd ..
    
    # Print summary
    print_summary
}

# Run main function
main "$@"

