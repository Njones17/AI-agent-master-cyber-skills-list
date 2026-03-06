---
name: using-git-worktrees
description: Use when starting security work that needs isolation from current workspace, before executing engagement plans, or when testing exploits that could affect the working tree — creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Required Tools

| Tool | Required | Fallback | Install |
|------|----------|----------|---------|
| git | ✅ Yes | No fallback — essential | Usually pre-installed |
| ripgrep (rg) | ⚡ Optional | grep → find | `brew install ripgrep` / `cargo install ripgrep` |

> **Cross-Platform Notes:**
> - **macOS**: Install GNU coreutils for `timeout` command: `brew install coreutils` (provides `gtimeout`)
> - **Linux/WSL**: `timeout` command is available by default

## Cross-Platform Helper Functions

Add these functions to your shell session for cross-platform compatibility:

```bash
# Cross-platform timeout wrapper
run_with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
  else
    # Perl fallback for macOS without coreutils
    perl -e 'use POSIX qw(SIGALRM); alarm shift; exec @ARGV or die "$!"' "$seconds" "$@"
  fi
}

# Cross-platform grep wrapper  
search_text() {
  if command -v rg >/dev/null 2>&1; then
    rg "$@"
  else
    grep -E "$@"
  fi
}

# Cross-platform PIPESTATUS alternative
# Usage: run_and_capture command arg1 arg2; EXIT_CODE=$?
run_and_capture() {
  "$@"
  return $?
}
```

## Tool Execution Protocol

   if [ $EXIT_CODE -eq 0 ]; then
     echo "SUCCESS: Worktree created at $WORKTREE_PATH"
   elif search_text -q "already exists" worktree_creation.log; then
     echo "INFO: Worktree branch already exists, removing old worktree"
     git worktree remove "$WORKTREE_PATH" 2>/dev/null
     # Retry creation
     git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
   else
     echo "TOOL_FAILURE: Failed to create worktree"
     echo "Diagnosis: $(cat worktree_creation.log)"
     echo ""
     echo "Possible causes:"
     echo "- Branch name already exists elsewhere"
     echo "- Filesystem permissions"
     echo "- Corrupted git repository"
     exit 1
   fi
   ```

4. **Safety verification with retry**
   ```bash
   # Check .gitignore with retry
   if ! git check-ignore -q .worktrees 2>/dev/null; then
     echo "WARNING: .worktrees is NOT ignored in .gitignore"
     echo "Fixing immediately..."

     # Add to .gitignore
     echo ".worktrees/" >> .gitignore 2>/dev/null

     # Verify fix
     if git check-ignore -q .worktrees 2>/dev/null; then
       echo "SUCCESS: .worktrees now ignored"
       # Stage and commit
       git add .gitignore
       git commit -m "chore: add .worktrees to .gitignore"
     else
       echo "TOOL_FAILURE: Could not add .worktrees to .gitignore"
       echo "Manual intervention required"
     fi
   fi
   ```

5. **Baseline verification with error checks**
   ```bash
   # Run project setup with validation
   cd "$WORKTREE_PATH"

   # Detect project type
   if [ -f package.json ]; then
     echo "Detected: Node.js project"
     echo "Running: npm install"

     run_with_timeout 120 npm install 2>&1 | tee npm_install.log
     if [ $? -eq 0 ]; then
       echo "SUCCESS: Dependencies installed"
     else
       echo "WARNING: npm install had issues"
       echo "Check: npm_install.log"
     fi
   elif [ -f Cargo.toml ]; then
     echo "Detected: Rust project"
     echo "Running: cargo build"

     run_with_timeout 300 cargo build 2>&1 | tee cargo_build.log
     if [ $? -eq 0 ]; then
       echo "SUCCESS: Project built successfully"
     else
       echo "WARNING: Build had errors or warnings"
       echo "Check: cargo_build.log"
     fi
   else
     echo "INFO: No package manager detected (manual project)"
   fi

   # Verify clean baseline
   if [ -f package.json ]; then
     run_with_timeout 60 npm test 2>&1 | tee npm_test.log
     if [ $? -eq 0 ]; then
       echo "BASELINE: All tests passing"
     else
       echo "WARNING: Baseline tests not passing"
       echo "This may not be a clean checkout"
     fi
   fi
   ```

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple engagements or exploit branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Selection Process

Follow this priority order:

### 1. Check Existing Directories

```bash
# Check in priority order
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check CLAUDE.md

```bash
rg -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**If preference specified:** Use it without asking.

### 3. Ask User

If no directory exists and no CLAUDE.md preference:

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/.config/superhackers/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

Fix broken things immediately:
1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents (especially exploit code, scan results, or engagement evidence) to the repository.

### For Global Directory (~/.config/superhackers/worktrees)

No .gitignore verification needed — outside project entirely.

## Creation Steps

### 1. Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. Create Worktree

```bash
# Determine full path
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superhackers/worktrees/*)
    path="~/.config/superhackers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 3. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. Verify Clean Baseline

Run scans or checks to ensure worktree starts clean:

```bash
# Verify the workspace is functional
# Use project-appropriate verification command
npm test          # Node.js projects
cargo test        # Rust projects
pytest            # Python projects
go test ./...     # Go projects
```

**If checks fail:** Report failures, ask whether to proceed or investigate.

**If checks pass:** Report ready.

### 5. Report Location

```
Worktree ready at <full-path>
Baseline checks passing (<N> checks, 0 failures)
Ready to begin <engagement-name / exploit-branch / target-analysis>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Checks fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Skipping ignore verification

- **Problem:** Worktree contents (exploit code, credentials, scan data) get tracked, pollute git status, risk exposure
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: existing > CLAUDE.md > ask

### Proceeding with failing baseline

- **Problem:** Can't distinguish new issues from pre-existing problems during testing
- **Fix:** Report failures, get explicit permission to proceed

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Auto-detect from project files (package.json, etc.)

## Example Workflows

### Isolated Exploit Development

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Check .worktrees/ - exists]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[Create worktree: git worktree add .worktrees/exploit-cve-2024-1234 -b exploit/cve-2024-1234]
[Run pip install -r requirements.txt]
[Run pytest - 12 passing]

Worktree ready at /Users/hacker/pentest-tools/.worktrees/exploit-cve-2024-1234
Baseline checks passing (12 tests, 0 failures)
Ready to develop exploit for CVE-2024-1234
```

### Parallel Target Analysis

```
You: I'm using the using-git-worktrees skill to set up isolated workspaces for parallel testing.

[Create worktree: git worktree add .worktrees/target-webapp -b engagement/webapp-assessment]
[Create worktree: git worktree add .worktrees/target-api -b engagement/api-assessment]
[Create worktree: git worktree add .worktrees/target-infra -b engagement/infra-assessment]

Worktrees ready:
  - .worktrees/target-webapp → webapp assessment workspace
  - .worktrees/target-api → API assessment workspace
  - .worktrees/target-infra → infrastructure assessment workspace

Ready to dispatch parallel agents (see superhackers:dispatching-parallel-agents)
```

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Skip baseline verification
- Proceed with failing checks without asking
- Assume directory location when ambiguous
- Skip CLAUDE.md check
- Store sensitive engagement data in unignored worktrees

**Always:**
- Follow directory priority: existing > CLAUDE.md > ask
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean baseline
- Consider data sensitivity when choosing worktree location

## Integration

**Called by:**
- **superhackers:security-assessment** — REQUIRED when setting up engagement workspace
- **superhackers:dispatching-parallel-agents** — REQUIRED before dispatching agents to isolated workspaces
- Any skill needing isolated workspace for exploit development or testing

**Pairs with:**
- **superhackers:finishing-an-engagement** — REQUIRED for cleanup after engagement complete
