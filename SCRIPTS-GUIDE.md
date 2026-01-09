# 🚀 Helper Scripts Guide

**For Non-Developers**: This guide explains how to use the automated scripts that make setting up and managing your projects super easy!

## 📦 What Are These Scripts?

These scripts are like automated assistants that do all the boring setup work for you. Instead of typing 20+ commands, you just run one script and it handles everything!

> **💡 Note About Paths**: In this guide, we use `/path/to/creators-training-2026` as a placeholder. Replace it with wherever you actually cloned the repository. For example: `~/creators-training-2026`, `~/dev/creators-training-2026`, or `/Users/yourname/projects/creators-training-2026`.

## 🎯 Quick Start

### Step 1: Install the Scripts (One Time Only)

1. **Open Terminal** (or Command Prompt on Windows)

2. **Navigate to the scripts folder** (wherever you cloned the repository):
   ```bash
   cd /path/to/creators-training-2026/scripts
   # Example: cd ~/creators-training-2026/scripts
   # Or: cd ~/dev/creators-training-2026/scripts
   ```

3. **Run the installer**:
   ```bash
   ./install-scripts.sh
   ```

4. **Restart your terminal** or run:
   ```bash
   source ~/.zshrc   # If you use zsh
   # OR
   source ~/.bashrc  # If you use bash
   ```

✅ **Done!** You can now use these scripts from anywhere!

---

## 🛠️ Available Scripts

### 1. 🎨 `setup-new-project.sh` - Create New Projects

**What it does:**
- Creates a new project from scratch
- Installs all necessary tools (TypeScript, testing framework)
- Copies professional development rules
- Sets up Git
- Creates documentation
- Validates everything works

**How to use:**
```bash
setup-new-project.sh my-awesome-app
```

**What you'll see:**

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Professional Project Setup                            ║
║    with TDD & AI Assistance                              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Checking Prerequisites
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️ Checking Node.js...
✅ Node.js found: v20.10.0
✅ npm found: 10.2.3
✅ Git found: git version 2.39.0
✅ All prerequisites met!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Creating Project: my-awesome-app
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️ Creating project directory...
✅ Project directory created
✅ Git initialized

...

🎉 Setup Complete!
```

**Color meanings:**
- 🟢 **Green ✅** = Success
- 🔴 **Red ❌** = Error (something failed)
- 🟡 **Yellow ⚠️** = Warning (might need attention)
- 🔵 **Blue ⚙️** = Working on it

---

### 2. 🔍 `verify-project.sh` - Check Your Project

**What it does:**
- Checks if all tools are installed
- Verifies cursor rules are present
- Checks project structure
- Tests if dependencies are installed
- Validates configurations
- Checks Git setup
- Runs tests

**How to use:**
```bash
cd my-awesome-app
verify-project.sh
```

**What you'll see:**

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Project Setup Verification                            ║
║    Checking your development environment                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Verifying project: my-awesome-app
Location: /Users/you/my-awesome-app

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔍 System Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Node.js: v20.10.0
✅ npm: 10.2.3
✅ Git: 2.39.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Verification Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Results:
  ✅ Passed:   18
  ❌ Failed:   0
  ⚠️ Warnings: 2

Score: 90%

✨ Great! Some minor improvements possible.
```

**When to use:**
- After setting up a new project
- When something isn't working
- Before starting development
- After pulling code from Git

---

### 3. 🧹 `cleanup-project.sh` - Clean Up Space

**What it does:**
- Removes build files (dist/, build/)
- Removes test coverage reports
- Removes cache files
- Removes temporary files
- Optionally removes node_modules (with confirmation)
- Shows how much space you freed

**How to use:**
```bash
cd my-awesome-app
cleanup-project.sh
```

**What you'll see:**

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Project Cleanup                                       ║
║    Free up disk space                                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Cleaning project: my-awesome-app

What would you like to clean?

  1. Quick clean (build outputs, coverage, caches)
  2. Full clean (includes node_modules - requires reinstall)
  3. Cancel

Choose an option [1-3]: 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🧹 Build Outputs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Removing dist/... ✅ Freed 2.3MB
Removing build/... ✅ Freed 1.5MB

...

✨ Cleanup Complete!
Total space freed: 5.8MB

✅ Project ready to use
```

**When to use:**
- When your disk is getting full
- Before pushing to Git
- After making many builds
- When starting fresh

---

### 4. 🔧 `troubleshoot.sh` - Fix Problems

**What it does:**
- Diagnoses common problems
- Offers to fix them automatically
- Checks Node.js version
- Checks for missing dependencies
- Verifies cursor rules
- Checks TypeScript errors
- Checks for failing tests
- Checks for port conflicts

**How to use:**
```bash
cd my-awesome-app
troubleshoot.sh
```

**What you'll see:**

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    Project Troubleshooter                                ║
║    Diagnose and fix common issues                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔍 Checking Dependencies
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ Issue: node_modules/ not found
  → Dependencies are not installed

Would you like to fix this now? [y/N]: y

⚙️ Installing dependencies...
✅ Dependencies installed successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found 1 issue(s)
Review the issues above and fix them for best results.

💡 Need more help?
  1. Run verify-project.sh for detailed checks
  2. Ask Cursor AI for assistance
  3. Check docs/DEVELOPMENT-METHODOLOGY.md
```

**When to use:**
- When something isn't working
- When you see error messages
- After pulling code from Git
- Before asking for help (it might fix it!)

---

## 📖 Common Scenarios

### Scenario 1: Starting a Brand New Project

```bash
# 1. Create the project
setup-new-project.sh my-new-app

# 2. Go into the project
cd my-new-app

# 3. Open in your code editor
cursor .  # or: code .

# 4. Start coding!
```

### Scenario 2: Something Isn't Working

```bash
# 1. Try troubleshooting first
cd my-project
troubleshoot.sh

# 2. If that doesn't help, verify everything
verify-project.sh

# 3. If still stuck, clean and reinstall
cleanup-project.sh  # Choose option 2 (full clean)
npm install
```

### Scenario 3: Running Out of Disk Space

```bash
# Clean all your projects
cd project1
cleanup-project.sh  # Choose option 1 (quick)

cd ../project2
cleanup-project.sh  # Choose option 1 (quick)

# ... repeat for each project
```

### Scenario 4: Before Sharing Your Project

```bash
cd my-project

# 1. Clean up
cleanup-project.sh  # Choose option 1

# 2. Verify everything works
verify-project.sh

# 3. If score is good, you're ready!
# 4. Push to Git or share
```

---

## 🎨 Understanding the Output

### Status Symbols
- ✅ = Success / Good / Passed
- ❌ = Error / Failed
- ⚠️ = Warning / Needs Attention
- ℹ️ = Information / Note
- 🔍 = Checking / Analyzing
- ⚙️ = Working / Processing
- 🚀 = Complete / Ready
- 💡 = Tip / Suggestion

### Colors
- **Green** 🟢 = Good news! Everything is working
- **Red** 🔴 = Problem! Something needs to be fixed
- **Yellow** 🟡 = Warning! Not critical but should look at it
- **Blue** 🔵 = Information or working on something
- **Cyan** 🔷 = Tips and suggestions
- **Purple** 🟣 = Headers and titles

---

## 🆘 Troubleshooting the Scripts

### "Permission denied"
```bash
# Make the script executable
chmod +x setup-new-project.sh
```

### "Command not found"
```bash
# Make sure you ran the installer
cd /path/to/creators-training-2026/scripts  # wherever you cloned it
./install-scripts.sh

# Then restart your terminal
```

### Scripts are slow
- This is normal! Installing dependencies takes time
- Be patient, especially on first run
- You'll see progress messages

### Script stopped with error
- Read the red error messages carefully
- They usually tell you what's wrong
- Try running `troubleshoot.sh` to fix it
- Or ask someone for help with the error message

---

## 💡 Pro Tips

1. **Always run from the project directory** (except `setup-new-project.sh`)
   ```bash
   cd my-project  # Go to your project first
   verify-project.sh  # Then run the script
   ```

2. **Read the output!** The scripts tell you what they're doing and what you need to do

3. **Use verify before troubleshoot**
   - `verify-project.sh` shows all problems
   - `troubleshoot.sh` fixes problems one by one

4. **Keep scripts updated**
   ```bash
   cd /path/to/creators-training-2026  # wherever you cloned it
   git pull  # Get latest version
   cd scripts
   ./install-scripts.sh  # Reinstall
   ```

5. **Scripts are safe!**
   - They won't delete your code
   - They ask before doing anything destructive
   - You can always say "no" to confirmations

---

## 🎓 What To Do After Setup

After running `setup-new-project.sh`, your project has:

✅ **Testing framework** - Run `npm test` to test your code
✅ **TypeScript** - Write safer code with types
✅ **Cursor AI rules** - Cursor knows your project standards
✅ **Documentation** - Check the `docs/` folder
✅ **Git** - Version control ready to go

**Next steps:**
1. Open the project in Cursor: `cursor .`
2. Read the README.md
3. Start coding!
4. Write tests first (TDD)
5. Ask Cursor for help: "Create a user login with tests"

---

## ❓ FAQ

**Q: Do I need to understand what the scripts do?**
A: No! That's the point. They do the boring work for you.

**Q: What if something goes wrong?**
A: Run `troubleshoot.sh` - it will try to fix it. If that doesn't help, ask for human help!

**Q: Can I use these for any project?**
A: Yes! They work for any Node.js/TypeScript project.

**Q: Will this delete my code?**
A: No! The scripts only remove build files and dependencies (which can be reinstalled). Your source code is safe.

**Q: How do I update the scripts?**
A: Pull the latest version from Git and run `install-scripts.sh` again.

**Q: Can I see what the script is doing?**
A: Yes! The scripts show you every step with colored messages.

---

## 🤝 Getting Help

If you're stuck:

1. **Run troubleshoot.sh** - It might fix it automatically
2. **Run verify-project.sh** - See what's wrong
3. **Read the error messages** - They usually explain the problem
4. **Copy the error** - Share it with someone who can help
5. **Check the docs** - `docs/DEVELOPMENT-METHODOLOGY.md` has more details

---

**Made with ❤️ for non-developers by developers**

Remember: These scripts are your friends! They're here to make your life easier. Don't be afraid to use them!

