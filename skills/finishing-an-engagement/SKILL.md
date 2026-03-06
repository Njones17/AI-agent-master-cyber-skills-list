---
name: finishing-an-engagement
description: Use when active testing is complete, all findings are verified, and you need to finalize the engagement — guides completion by presenting structured options for report delivery, evidence archival, artifact cleanup, and client handoff
---

# Finishing an Engagement

## Required Tools

> This is a workflow completion skill. It requires no external security tools — it ensures proper engagement wrap-up, evidence collection, and handoff.

| Tool | Required | Fallback | Install |
|------|----------|----------|---------|
| ripgrep (rg) | ⚡ Optional | grep → find | `brew install ripgrep` / `cargo install ripgrep` |
| tar | ⚡ Optional | manual copy | Usually pre-installed |
| git | ⚡ Optional | manual file operations | Usually pre-installed |

## Tool Execution Protocol

**MANDATORY**: All file operations and validations MUST follow this protocol:

1. **Validate file existence before operations**
   ```bash
   # Check if findings directory exists before verification
   if [ ! -d "findings" ]; then
     echo "WARNING: No findings directory found"
     echo "Creating findings directory structure"
     mkdir -p findings

     # Check if creation succeeded
     if [ $? -ne 0 ]; then
       echo "TOOL_FAILURE: Cannot create findings directory"
       echo "Current directory: $(pwd)"
       echo "Permissions: $(ls -ld . | awk '{print $1}')"
       exit 1
     fi
   fi
   ```

2. **Validate findings with error handling**
   ```bash
   # Check findings verification status
   if [ -d "findings" ]; then
     VERIFIED_COUNT=$(rg -c "Status: Verified" findings/*.md 2>/dev/null || echo "0")
     UNVERIFIED_COUNT=$(rg -c "Status: Unverified" findings/*.md 2>/dev/null || echo "0")

     echo "Verified findings: $VERIFIED_COUNT"
     echo "Unverified findings: $UNVERIFIED_COUNT"

     if [ "$UNVERIFIED_COUNT" -gt 0 ]; then
       echo "ERROR: Cannot complete engagement with unverified findings"
       echo ""
       echo "Unverified findings:"
       rg -l "Status: Unverified" findings/*.md 2>/dev/null | while read file; do
         echo "  - $(basename "$file")"
       done

       # Exit with error code
       exit 1
     fi
   else
     echo "WARNING: No findings directory to verify"
     echo "Proceeding with no findings (empty assessment)"
   fi
   ```

3. **File operations with validation**
   ```bash
   # Create evidence archive with validation
   ARCHIVE_NAME="evidence-archive-$(date +%Y%m%d).tar.gz"

   echo "Creating evidence archive..."

   # Create archive with error checking
   tar czf "$ARCHIVE_NAME" \
     findings/ scans/ logs/ \
     2>&1 | tee archive_creation.log

   EXIT_CODE=$?

   if [ $EXIT_CODE -eq 0 ]; then
     # Verify archive was created
     if [ -f "$ARCHIVE_NAME" ]; then
       ARCHIVE_SIZE=$(stat -f%z "$ARCHIVE_NAME" 2>/dev/null || stat -c%s "$ARCHIVE_NAME" 2>/dev/null)
       echo "SUCCESS: Archive created (${ARCHIVE_SIZE} bytes)"
     else
       echo "TOOL_FAILURE: Archive file not created"
     fi
   else
     echo "TOOL_FAILURE: tar failed with exit code $EXIT_CODE"
     echo "Diagnosis: $(cat archive_creation.log | tail -10)"
     exit 1
   fi
   ```

4. **Git operations with validation**
   ```bash
   # Check if in worktree before cleanup
   CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)

   if [ -z "$CURRENT_BRANCH" ]; then
     echo "INFO: Not in a git repository or detached HEAD state"
   else
     echo "Current branch: $CURRENT_BRANCH"

     # Check if this is a worktree
     WORKTREE_INFO=$(git worktree list 2>/dev/null | rg "$CURRENT_BRANCH" || echo "")

     if [ -n "$WORKTREE_INFO" ]; then
       echo "Detected: Currently in a git worktree"

       # Remove worktree with confirmation
       WORKTREE_PATH=$(pwd)
       PARENT_REPO=$(git rev-parse --show-toplevel)

       echo "Worktree path: $WORKTREE_PATH"
       echo "Parent repo: $PARENT_REPO"

       # Change to parent repo for worktree removal
       cd "$PARENT_REPO"

       echo "Removing worktree..."
       git worktree remove "$WORKTREE_PATH" 2>&1 | tee worktree_removal.log

       if [ $? -eq 0 ]; then
         echo "SUCCESS: Worktree removed"
       else
         echo "WARNING: Worktree removal had issues"
         echo "Manual removal may be required"
       fi
     fi
   fi
   ```

5. **Secure deletion with validation**
   ```bash
   # Secure file deletion with validation (only for Option 4)
   if [ "$CHOICE" = "4" ]; then
     echo "Performing secure deletion..."

     # Use shred if available, otherwise rm
     if command -v shred >/dev/null 2>&1; then
       find evidence/ -type f -exec shred -u {} \; 2>&1 | tee shred.log
       EXIT_CODE=$?

       if [ $EXIT_CODE -eq 0 ]; then
         echo "SUCCESS: Files securely deleted"
       else
         echo "TOOL_FAILURE: shred had issues"
         echo "Fallback: Using rm"
         find evidence/ -type f -delete
       fi
     else
       echo "shred not found, using rm for deletion"
       find evidence/ -type f -delete
     fi

     # Remove directories
     rm -rf findings/ scans/ logs/ report/

     # Verify deletion
     if [ -d "findings" ] || [ -d "evidence" ]; then
       echo "TOOL_FAILURE: Some directories could not be removed"
       ls -la | rg "findings|evidence|scans|logs|report"
     else
       echo "SUCCESS: All directories removed"
     fi
   fi
   ```

## Overview

Guide completion of a security engagement by presenting clear options and handling the chosen finalization workflow.

**Core principle:** Verify findings → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-an-engagement skill to complete this engagement."

## The Process

### Step 1: Verify Findings

**Before presenting options, verify all findings are confirmed:**

```bash
# Check that all findings have been verified
# Review the findings log for any unverified entries
rg -c "Status: Verified" findings/*.md
rg -c "Status: Unverified" findings/*.md
```

**If unverified findings remain:**
```
Unverified findings detected (<N> unverified). Must verify before completing:

[Show unverified findings]

Cannot proceed with report delivery until all findings are verified or explicitly marked as false positives.
Load superhackers:vulnerability-verification to confirm remaining findings.
```

Stop. Don't proceed to Step 2.

**If all findings verified:** Continue to Step 2.

### Step 2: Determine Engagement Scope

```bash
# Review engagement metadata
cat scope.md 2>/dev/null || cat engagement-plan.md 2>/dev/null
# Check what deliverables were promised
rg -i "deliverable" scope.md 2>/dev/null
```

Or ask: "This engagement covers [target] with [deliverables] — is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Engagement testing complete. All findings verified. What would you like to do?

1. Finalize report and deliver to client
2. Archive evidence and keep engagement workspace open
3. Keep the engagement as-is (I'll handle delivery later)
4. Discard this engagement's artifacts

Which option?
```

**Don't add explanation** — keep options concise.

### Step 4: Execute Choice

#### Option 1: Finalize Report and Deliver

```bash
# Generate final report from verified findings
# Load superhackers:writing-security-reports if not already loaded

# Compile all evidence into report appendices
mkdir -p report/appendices
cp evidence/screenshots/* report/appendices/ 2>/dev/null
cp evidence/pcaps/* report/appendices/ 2>/dev/null
cp evidence/requests/* report/appendices/ 2>/dev/null

# Generate executive summary
# Generate technical findings with CVSS scores
# Generate remediation roadmap

# Package deliverable
tar czf engagement-report-$(date +%Y%m%d).tar.gz report/

# Clean up test artifacts from target (if applicable)
# Remove uploaded shells, test accounts, planted files
```

Then: Cleanup workspace (Step 5)

#### Option 2: Archive Evidence and Keep Open

```bash
# Archive all evidence with timestamps
tar czf evidence-archive-$(date +%Y%m%d).tar.gz \
  evidence/ findings/ scans/ logs/

# Store archive in secure location
mv evidence-archive-*.tar.gz ~/.engagements/$(basename $(pwd))/

# Keep workspace intact for potential follow-up testing
```

Report: "Evidence archived. Workspace preserved for follow-up."

**Don't cleanup workspace.**

#### Option 3: Keep As-Is

Report: "Keeping engagement workspace at <path>. All findings preserved."

**Don't cleanup workspace.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- All findings and evidence from this engagement
- Scan results and logs
- Draft reports
- Worktree at <path> (if applicable)

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
# Securely wipe sensitive engagement data
find evidence/ -type f -exec shred -u {} \; 2>/dev/null
rm -rf findings/ scans/ logs/ report/

# Remove engagement branch if using git
git checkout main
git branch -D engagement/<name>
```

Then: Cleanup workspace (Step 5)

### Step 5: Cleanup Workspace

**For Options 1 and 4:**

Check if in worktree:
```bash
git worktree list | rg $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

Remove temporary scan artifacts:
```bash
# Clean up tool output files
rm -f *.nmap *.gnmap *.xml 2>/dev/null
rm -f ffuf_*.json nuclei_*.json 2>/dev/null
rm -f *.pot hashcat.* 2>/dev/null
```

**For Options 2 and 3:** Keep workspace intact.

## Quick Reference

| Option | Report | Archive | Keep Workspace | Cleanup Artifacts |
|--------|--------|---------|----------------|-------------------|
| 1. Finalize & deliver | ✓ | ✓ | - | ✓ |
| 2. Archive & keep open | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (secure wipe) |

### Context Window Awareness

During long engagements, prior conversation context may be summarized or compressed. When you detect summarized content (shorter-than-expected prior messages, loss of technical detail):

1. **Never trust summarized values** for: IP addresses, port numbers, URLs, credentials, CVSS scores, CWE IDs
2. **Re-verify** critical data by re-running the discovery command rather than quoting from summary
3. **Maintain a running findings log** in a file (not just in conversation) — this survives context compression
4. **Flag uncertainty**: If a prior finding's details are unclear from summary, state "details from prior context, re-verification recommended" in the report

## Common Mistakes

**Skipping finding verification**
- **Problem:** Deliver report with false positives, destroy credibility
- **Fix:** Always verify every finding before offering completion options

**Open-ended questions**
- **Problem:** "What should I do with the results?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Leaving test artifacts on target**
- **Problem:** Uploaded shells, test accounts, planted files persist after engagement
- **Fix:** Always clean up artifacts from target systems during finalization

**No confirmation for discard**
- **Problem:** Accidentally delete engagement evidence
- **Fix:** Require typed "discard" confirmation

**Insecure evidence handling**
- **Problem:** Sensitive findings, credentials, or PII left on disk unprotected
- **Fix:** Use secure deletion (shred) for discarded data, encrypted archives for retained data

## Red Flags

**Never:**
- Proceed with unverified findings in the report
- Deliver a report without executive summary and remediation guidance
- Delete evidence without confirmation
- Leave test artifacts (shells, accounts, files) on target systems
- Store engagement data in unencrypted, unprotected locations

**Always:**
- Verify all findings before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up test artifacts from target systems
- Securely handle sensitive engagement data

## Integration

**Called by:**
- **superhackers:security-assessment** (final phase) — After all testing phases complete
- **superhackers:vulnerability-verification** — After all findings are verified

**Pairs with:**
- **superhackers:using-git-worktrees** — Cleans up worktree created by that skill
- **superhackers:writing-security-reports** — Generates final deliverable during Option 1

### Execution Discipline

- **Persist**: Continue working through ALL steps of the Core Pattern until completion criteria are met. Do NOT stop after a single tool run or partial result.
- **Scope**: Work ONLY within this skill's methodology. Do NOT jump to another phase.
- **Negative Results**: If thorough testing reveals no vulnerabilities, that IS a valid result. Document what was tested and report "no findings" — do NOT invent issues.
