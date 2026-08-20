# canvas-cli documentation snapshot

Git commit: 162e7899127f0b7d501fdbe1f86a7ab4064d10ff
Generated: 2026-08-20

This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: skills/canvas-cli/SKILL.md, skills/canvas-cli/references/*.md, docs/tutorials/scripting.md, docs/best-practices.md, CHANGELOG.md
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
````
docs/
  tutorials/
    scripting.md
  best-practices.md
skills/
  canvas-cli/
    references/
      auth-and-config.md
      canvas-commands.md
      output-and-filtering.md
    SKILL.md
CHANGELOG.md
````

# Files

## File: docs/tutorials/scripting.md
````markdown
# Scripting & Automation Tutorial

Learn how to automate Canvas tasks with shell scripts.

## Overview

Canvas CLI's JSON output makes it perfect for automation:

- Integrate with shell scripts and cron jobs
- Process data with `jq`
- Build custom workflows

## Prerequisites

- Canvas CLI installed and authenticated
- Basic shell scripting knowledge
- `jq` installed (for JSON processing)

## Basic Scripting

### Using JSON Output

Always use `-o json` for scripting:

```bash
# Get all course IDs
canvas courses list -o json | jq '.[].id'

# Get courses as array
courses=$(canvas courses list -o json | jq -r '.[].id')
for course in $courses; do
  echo "Processing course: $course"
done
```

### Filtering with jq

```bash
# Find active courses
canvas courses list -o json | jq '.[] | select(.workflow_state == "available")'

# Get course names containing "CS"
canvas courses list -o json | jq '.[] | select(.name | contains("CS")) | .name'

# Count enrollments
canvas users list --course-id 123 -o json | jq length
```

## Example Scripts

### Export All Grades

Export grades for all assignments in a course:

```bash
#!/bin/bash
COURSE_ID=$1

if [ -z "$COURSE_ID" ]; then
  echo "Usage: $0 <course_id>"
  exit 1
fi

# Get all assignments
assignments=$(canvas assignments list --course-id $COURSE_ID -o json | jq -r '.[].id')

# Create output directory
mkdir -p grades/$COURSE_ID

# Export each assignment's submissions
for assignment in $assignments; do
  echo "Exporting assignment $assignment..."
  canvas submissions list \
    --course-id $COURSE_ID \
    --assignment-id $assignment \
    -o csv > "grades/$COURSE_ID/assignment_$assignment.csv"
done

echo "Done! Grades exported to grades/$COURSE_ID/"
```

### Bulk User Enrollment

Enroll users from a CSV file:

```bash
#!/bin/bash
COURSE_ID=$1
CSV_FILE=$2

if [ -z "$COURSE_ID" ] || [ -z "$CSV_FILE" ]; then
  echo "Usage: $0 <course_id> <csv_file>"
  exit 1
fi

# CSV columns: user_id,type (e.g. 42,StudentEnrollment)
# Skip header and process each line
tail -n +2 "$CSV_FILE" | while IFS=, read -r user_id type; do
  echo "Enrolling user $user_id as $type..."
  canvas enrollments create \
    --course-id $COURSE_ID \
    --user-id "$user_id" \
    --type "$type"
done
```

### Course Health Check

Check course configuration and report issues:

```bash
#!/bin/bash
COURSE_ID=$1

echo "=== Course Health Check ==="
echo ""

# Get course info
course=$(canvas courses get $COURSE_ID -o json)
echo "Course: $(echo $course | jq -r '.name')"
echo "State: $(echo $course | jq -r '.workflow_state')"
echo ""

# Check modules
module_count=$(canvas modules list --course-id $COURSE_ID -o json | jq length)
echo "Modules: $module_count"

# Check assignments
assignment_count=$(canvas assignments list --course-id $COURSE_ID -o json | jq length)
echo "Assignments: $assignment_count"

# Check unpublished items
unpublished=$(canvas modules list --course-id $COURSE_ID -o json | jq '[.[] | select(.published == false)] | length')
echo "Unpublished modules: $unpublished"

# Check for missing due dates
no_due_date=$(canvas assignments list --course-id $COURSE_ID -o json | jq '[.[] | select(.due_at == null)] | length')
echo "Assignments without due date: $no_due_date"
```

### Automated Backup

Back up course content daily:

```bash
#!/bin/bash
# Add to crontab: 0 2 * * * /path/to/backup.sh

BACKUP_DIR="/backups/canvas"
DATE=$(date +%Y-%m-%d)

# Get all courses
courses=$(canvas courses list -o json | jq -r '.[].id')

for course_id in $courses; do
  course_name=$(canvas courses get $course_id -o json | jq -r '.name' | tr ' ' '_')
  output_dir="$BACKUP_DIR/$DATE/$course_name"
  mkdir -p "$output_dir"

  # Export course data
  canvas courses get $course_id -o json > "$output_dir/course.json"
  canvas modules list --course-id $course_id -o json > "$output_dir/modules.json"
  canvas assignments list --course-id $course_id -o json > "$output_dir/assignments.json"
  canvas pages list --course-id $course_id -o json > "$output_dir/pages.json"

  echo "Backed up: $course_name"
done

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -type d -mtime +30 -exec rm -rf {} \;
```

## Advanced Patterns

### Parallel Processing

Process multiple courses in parallel:

```bash
#!/bin/bash
# Process courses in parallel (max 4 at a time)
canvas courses list -o json | jq -r '.[].id' | \
  xargs -P 4 -I {} bash -c 'process_course {}'

process_course() {
  course_id=$1
  canvas assignments list --course-id $course_id -o json > "course_$course_id.json"
}
export -f process_course
```

### Error Handling

Robust error handling in scripts:

```bash
#!/bin/bash
set -e  # Exit on error

handle_error() {
  echo "Error on line $1"
  exit 1
}
trap 'handle_error $LINENO' ERR

# Check if canvas CLI is available
if ! command -v canvas &> /dev/null; then
  echo "Canvas CLI not found"
  exit 1
fi

# Verify authentication
if ! canvas auth status &> /dev/null; then
  echo "Not authenticated. Run: canvas auth login"
  exit 1
fi

# Your script logic here
canvas courses list -o json
```

### Environment-Based Configuration

Use different instances based on environment:

```bash
#!/bin/bash
# Set instance based on environment
case "$CANVAS_ENV" in
  production)
    INSTANCE="production"
    ;;
  staging)
    INSTANCE="sandbox"
    ;;
  *)
    INSTANCE="sandbox"  # Default to sandbox
    ;;
esac

canvas courses list --instance $INSTANCE -o json
```

## Debugging with Dry-Run Mode

The `--dry-run` flag prints the equivalent curl command instead of executing HTTP requests. This is invaluable for debugging, learning the Canvas API, and building scripts.

### Basic Usage

```bash
# See what API call would be made
canvas --dry-run courses list

# Output:
# curl -X GET 'https://canvas.example.com/api/v1/courses' \
#   -H 'Authorization: Bearer [REDACTED]' \
#   -H 'Content-Type: application/json' \
#   -H 'Accept: application/json' \
#   -H 'User-Agent: canvas-cli/1.10.0'
```

### Show Token for Testing

By default, tokens are redacted. Use `--show-token` to see the actual token:

```bash
canvas --dry-run --show-token courses list
```

!!! warning "Security"
    Only use `--show-token` when you need to copy the curl command for testing. Never share output containing your token.

### Debug with Masquerading

See how masquerading affects API calls:

```bash
canvas --dry-run --as-user 12345 courses list

# Output includes the as_user_id parameter:
# curl -X GET 'https://canvas.example.com/api/v1/courses?as_user_id=12345' \
#   -H 'Authorization: Bearer [REDACTED]' \
#   ...
```

### Use Cases

**Learning the API**: See exactly what endpoints and parameters Canvas CLI uses:

```bash
# See how submissions are graded
canvas --dry-run submissions grade --course-id 123 --assignment-id 456 --user-id 789 --posted-grade "A"
```

**Building Scripts**: Generate curl commands for use in other tools:

```bash
# Generate curl command and pipe to clipboard (macOS)
canvas --dry-run --show-token courses list | pbcopy
```

**Troubleshooting**: Verify the request before it's sent:

```bash
# Check URL construction with complex options
canvas --dry-run assignments list --course-id 123 --include submissions,score_statistics
```

## Tips

!!! tip "Test in Sandbox"
    Always test scripts against a sandbox instance before running on production.

!!! tip "Rate Limiting"
    Canvas CLI handles rate limiting automatically, but for large batch operations, consider adding delays.

!!! tip "Logging"
    Add timestamps and logging for long-running scripts:
    ```bash
    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    }
    log "Starting process..."
    ```

!!! warning "Credentials"
    Never hardcode tokens in scripts. Use environment variables or the config file.
````

## File: docs/best-practices.md
````markdown
# Canvas CLI Best Practices

This guide covers best practices for using Canvas CLI effectively and efficiently.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Authentication](#authentication)
- [Working with Multiple Instances](#working-with-multiple-instances)
- [Productivity Features](#productivity-features)
- [Output and Filtering](#output-and-filtering)
- [Scripting and Automation](#scripting-and-automation)
- [Common Workflows](#common-workflows)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)

---

## Initial Setup

### 1. Install Shell Completion

Enable tab completion for faster command entry:

```bash
# Bash
canvas completion bash > /etc/bash_completion.d/canvas

# Zsh
canvas completion zsh > "${fpath[1]}/_canvas"

# Fish
canvas completion fish > ~/.config/fish/completions/canvas.fish
```

### 2. Run Diagnostics

Verify your installation is working correctly:

```bash
canvas doctor
```

This checks connectivity, authentication, and configuration.

### 3. Enable Auto-Updates

Stay current with the latest features and fixes:

```bash
canvas update enable
canvas update status
```

---

## Authentication

### Choose the Right Method

| Method | Use Case | Security |
|--------|----------|----------|
| OAuth (default) | Interactive use, personal accounts | High - tokens auto-refresh |
| API Token | Scripts, automation, CI/CD | Medium - store securely |

### OAuth Login (Recommended for Interactive Use)

```bash
# Login with browser-based OAuth
canvas auth login https://canvas.example.com

# Login to a named instance
canvas config add prod --url https://canvas.example.com
canvas auth login --instance prod
```

### API Token (For Automation)

```bash
# Set API token for an instance
canvas auth token set myinstance

# Use in scripts (set environment variable)
export CANVAS_TOKEN="your-token-here"
```

### Check Authentication Status

```bash
canvas auth status
```

---

## Working with Multiple Instances

### Configure Named Instances

```bash
# Add instances
canvas config add prod --url https://canvas.example.com
canvas config add staging --url https://staging.canvas.example.com
canvas config add dev --url https://dev.canvas.example.com

# List all instances
canvas config list

# Switch between instances
canvas config use prod
canvas config use staging
```

### Per-Command Instance Override

```bash
# Use a specific instance for one command
canvas courses list --instance staging
```

### Set Default Account

For admin operations, set a default account ID for an instance:

```bash
canvas config account production 1
```

---

## Productivity Features

### Command Aliases

Create shortcuts for frequently used commands:

```bash
# Create aliases
canvas alias set courses "courses list"
canvas alias set hw "assignments list --course-id 123"
canvas alias set ungraded "submissions list --workflow-state submitted"
canvas alias set students "users list --enrollment-type student"

# Use aliases
canvas courses
canvas hw
canvas ungraded --course-id 456 --assignment-id 789

# Manage aliases
canvas alias list
canvas alias delete hw
```

**Best Practices for Aliases:**

- Use short, memorable names
- Include common flags you always use
- Don't include IDs that change frequently (use context instead)

### Context Management

Set default values to avoid repetitive typing:

```bash
# Set course context for a work session
canvas context set course 12345

# Commands that support context use it automatically
canvas assignments list      # Uses course 12345
canvas assignments get 456   # Uses course 12345

# View current context
canvas context show

# Clear when switching tasks
canvas context clear
```

Context is currently applied by `assignments list` and `assignments get`;
other commands still require explicit flags (see [Context Management](user-guide/context.md)).

**Best Practices for Context:**

- Set context at the start of a focused work session
- Clear context when switching courses/tasks
- Use explicit flags when working across multiple courses
- Context + aliases = maximum efficiency

### Combine Aliases with Context

```bash
# Set up your workflow
canvas context set course 12345
canvas alias set hw "assignments list"
canvas alias set grade "submissions grade --course-id 12345 --assignment-id 456"

# Efficient grading
canvas hw                    # context provides the course ID
canvas grade --user-id 111 --score 95 --comment "Great work!"
canvas grade --user-id 222 --score 88
```

---

## Output and Filtering

### Choose the Right Output Format

| Format | Use Case |
|--------|----------|
| `table` | Human reading in terminal (default) |
| `json` | Scripting, piping to jq, automation |
| `yaml` | Configuration files, readable structured data |
| `csv` | Spreadsheet import, Excel, Google Sheets |

```bash
# Examples
canvas courses list                    # Table for viewing
canvas courses list -o json            # JSON for scripts
canvas users list -o csv > users.csv   # CSV for spreadsheets
```

### Filter Results

```bash
# Text filter (case-insensitive, searches all fields)
canvas courses list --filter "Fall 2024"
canvas users list --course-id 123 --filter "student"

# Select specific columns
canvas assignments list --course-id 123 --columns id,name,due_at

# Sort results
canvas assignments list --course-id 123 --sort due_at      # Ascending
canvas assignments list --course-id 123 --sort -due_at     # Descending

# Combine all options
canvas assignments list --course-id 123 \
  --filter "exam" \
  --columns id,name,due_at,points_possible \
  --sort -due_at
```

### Limit Results

```bash
# Get only first 10 results
canvas courses list --limit 10

# Useful for testing or quick checks
canvas submissions list --course-id 123 --assignment-id 456 --limit 5
```

---

## Scripting and Automation

### Use JSON Output

Always use `-o json` in scripts for reliable parsing:

```bash
#!/bin/bash
# Get all course IDs
COURSES=$(canvas courses list -o json | jq -r '.[].id')

for COURSE_ID in $COURSES; do
    echo "Processing course $COURSE_ID"
    canvas assignments list --course-id "$COURSE_ID" -o json
done
```

### Dry-Run for Testing

Preview commands before executing:

```bash
# See what API calls would be made
canvas assignments create --course-id 123 --name "Test" --dry-run

# Shows curl command with redacted token
curl -X POST 'https://canvas.example.com/api/v1/courses/123/assignments' \
  -H 'Authorization: Bearer [REDACTED]' \
  ...
```

### Bulk Operations

Use CSV for bulk grading:

```bash
# Prepare grades.csv:
# user_id,assignment_id,score,comment
# 123,456,95,Great work!
# 124,456,88,Good effort

canvas submissions bulk-grade \
  --course-id 123 \
  --csv-file grades.csv
```

### Error Handling in Scripts

```bash
#!/bin/bash
set -e  # Exit on error

# Check authentication first
if ! canvas auth status > /dev/null 2>&1; then
    echo "Not authenticated. Run: canvas auth login"
    exit 1
fi

# Proceed with operations
canvas courses list -o json
```

---

## Common Workflows

### Grading Workflow

```bash
COURSE=12345
ASSIGNMENT=67890

# 1. List ungraded submissions
canvas submissions list --course-id $COURSE --assignment-id $ASSIGNMENT \
  --workflow-state submitted

# 2. Grade individual submissions
canvas submissions grade --course-id $COURSE --assignment-id $ASSIGNMENT \
  --user-id 111 --score 95 --comment "Excellent!"
canvas submissions grade --course-id $COURSE --assignment-id $ASSIGNMENT \
  --user-id 222 --score 88

# 3. Or bulk grade from CSV (columns: user_id,assignment_id,score,comment)
canvas submissions bulk-grade --course-id $COURSE --csv-file grades.csv
```

### Course Setup Workflow

```bash
# 1. Create assignment groups
canvas assignment-groups create --course-id 123 --name "Homework" --weight 30
canvas assignment-groups create --course-id 123 --name "Exams" --weight 50
canvas assignment-groups create --course-id 123 --name "Projects" --weight 20

# 2. Create assignments
canvas assignments create --course-id 123 \
  --name "Homework 1" \
  --group-id 456 \
  --points 100 \
  --due-at "2024-09-15T23:59:00Z"

# 3. Create modules
canvas modules create --course-id 123 --name "Week 1"
canvas modules items create --course-id 123 --module-id 789 \
  --type Assignment --content-id 456
```

### User Management Workflow

```bash
# List students in a course
canvas users list --course-id 123 --enrollment-type student

# Search for a user (account-wide)
canvas users search "john"

# Export to spreadsheet
canvas users list --course-id 123 -o csv > students.csv
```

### Course Migration Workflow

```bash
# Sync from source to destination
# canvas sync course <source-instance> <source-course-id> <target-instance> <target-course-id>
canvas sync course prod 123 staging 456 --interactive
```

---

## Performance Tips

### Enable Caching

Caching is enabled by default. Manage it as needed:

```bash
# View cache stats
canvas cache stats

# Clear cache when data is stale
canvas cache clear

# Disable cache for one command
canvas courses list --no-cache
```

### Use Pagination Wisely

```bash
# For large datasets, use --limit to paginate manually
canvas users list --course-id 123 --limit 100

# Or let the CLI handle it (may take time for large datasets)
canvas users list --course-id 123
```

### Batch Operations

For multiple similar operations, use bulk commands when available:

```bash
# Slow: Individual grade commands
for id in 1 2 3 4 5; do
    canvas submissions grade --course-id 123 --assignment-id 456 \
      --user-id $id --score 100
done

# Fast: Bulk grade from CSV
canvas submissions bulk-grade --course-id 123 --csv-file grades.csv
```

---

## Troubleshooting

### Run Diagnostics

```bash
canvas doctor
```

### Enable Verbose Output

```bash
canvas courses list -v
```

### Check API Calls

```bash
# See exact API request
canvas courses list --dry-run
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Not authenticated" | Run `canvas auth login` |
| "Rate limited" | Wait and retry, or reduce request frequency |
| "Course not found" | Check course ID and permissions |
| "Token expired" | Re-authenticate with `canvas auth login` |

### Clear State

```bash
# Clear all cached data
canvas cache clear

# Clear context
canvas context clear

# Re-authenticate
canvas auth logout
canvas auth login
```

---

## Quick Reference

### Essential Commands

```bash
canvas auth login                 # Authenticate
canvas courses list               # List courses
canvas assignments list -c 123    # List assignments
canvas submissions list -c 123 -a 456  # List submissions
canvas context set course 123     # Set context
canvas alias set x "command"      # Create alias
```

### Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--output` | `-o` | Output format (table/json/yaml/csv) |
| `--verbose` | `-v` | Show detailed output |
| `--filter` | | Filter results by text |
| `--columns` | | Select columns to display |
| `--sort` | | Sort by field (- for descending) |
| `--limit` | | Limit number of results |
| `--dry-run` | | Show curl command without executing |
| `--no-cache` | | Bypass cache |
| `--instance` | | Use specific Canvas instance |

### Getting Help

```bash
canvas --help              # General help
canvas <command> --help    # Command-specific help
canvas doctor              # Diagnose issues
```
````

## File: skills/canvas-cli/references/auth-and-config.md
````markdown
# Canvas CLI — auth, instances, and context

Loaded on demand by the `canvas-cli` skill. Authoritative docs:
https://jjuanrivvera.github.io/canvas-cli/getting-started/authentication/

## Three auth methods

| Method | Setup | Best for |
|---|---|---|
| Environment variables | `export CANVAS_URL=… CANVAS_TOKEN=…` | CI/CD, containers, one-off scripts |
| API token | `canvas auth token set <name> --url URL --token 7~…` | Personal use, simplest persistent setup |
| OAuth 2.0 + PKCE | `canvas auth login --instance URL` | Most secure; tokens in OS keychain |

Precedence (highest first):

1. `CANVAS_URL` + `CANVAS_TOKEN` env vars — when both are set, env-auth mode is
   used and `--instance`/`default_instance` are ignored.
2. API token stored in config (`canvas auth token set`).
3. OAuth tokens in the system keychain (`canvas auth login`).

Tokens are generated in Canvas under **Account → Settings → Approved
Integrations → + New Access Token** (shown only once).

## Environment variables

| Variable | Meaning | Default |
|---|---|---|
| `CANVAS_URL` | Canvas instance URL (enables env-auth with token) | from config |
| `CANVAS_TOKEN` | API access token | from config/keyring |
| `CANVAS_REQUESTS_PER_SEC` | Rate limit in env-auth mode | `5.0` |

Output format and caching are flag-controlled (`-o`, `--no-cache`) — there are
no `CANVAS_OUTPUT`/`CANVAS_NO_CACHE` env vars.

CI example (GitHub Actions):

```yaml
- name: Run Canvas CLI
  env:
    CANVAS_URL: ${{ secrets.CANVAS_URL }}
    CANVAS_TOKEN: ${{ secrets.CANVAS_TOKEN }}
  run: canvas courses list -o json
```

## Multiple instances

```bash
canvas config add production --url https://canvas.instructure.com
canvas config add staging --url https://staging.canvas.example.com
canvas config list                  # see all + which is default
canvas config use staging           # switch default
canvas courses list --instance production   # one-off override
canvas auth login --instance production     # authenticate each separately
```

Mixing auth types per instance is fine (OAuth for prod, token for sandbox);
`canvas auth status` shows the auth type and state of every instance.

Config lives at `~/.canvas-cli/config.yaml`:

```yaml
default_instance: production
instances:
  production:
    url: https://canvas.instructure.com
context:
  course_id: 12345
```

## Context (default IDs)

Store default IDs for a working session:

```bash
canvas context set course 12345      # fills --course-id for assignments list/get
canvas context set assignment 67890  # stored, not yet consumed by commands
canvas context set user 111          # stored, not yet consumed by commands
canvas context set account 1         # stored, not yet consumed by commands
canvas context show
canvas context clear [course|assignment|user|account]
```

Only `assignments list`/`assignments get` read the course context today; pass
explicit flags everywhere else. Explicit flags always beat context. Before
acting on the user's behalf, run `canvas context show` — a stale context can
silently target the wrong course.

## Headless / remote auth

OAuth on a machine without a browser:

```bash
canvas auth login --instance https://myschool.instructure.com --mode oob
```

Prints an authorization URL, then prompts for the pasted code. For fully
non-interactive setups prefer env vars or `auth token set`.

## Verification

```bash
canvas auth status     # per-instance auth type + state
canvas doctor          # full diagnostics: binary, config, auth, connectivity
canvas users me        # confirms who the API sees you as
```
````

## File: skills/canvas-cli/references/canvas-commands.md
````markdown
# Canvas CLI — command cheatsheet

Condensed reference loaded on demand by the `canvas-cli` skill. Authoritative
docs: https://jjuanrivvera.github.io/canvas-cli/

## Global flags (any command)

| Flag | Meaning |
|---|---|
| `-o, --output table\|json\|yaml\|csv` | Output format (default table) |
| `--filter TEXT` | Case-insensitive substring match across all fields |
| `--columns a,b,c` | Select columns to display |
| `--sort field` / `--sort -field` | Sort ascending / descending |
| `--limit N` | Cap list results (0 = unlimited) |
| `--instance NAME` | Use a specific configured Canvas instance |
| `--dry-run` | Print the request as a curl command, send nothing |
| `--show-token` | Don't redact auth in `--dry-run` output |
| `--no-cache` | Bypass the response cache |
| `--as-user ID` | Masquerade as another user (admin permission required) |
| `--quiet` | Data and errors only (for scripts) |
| `-v, --verbose` | Debug logging to stderr |

## Meta commands

```bash
canvas version
canvas doctor                                   # install/auth/connectivity diagnostics
canvas auth login | status | logout
canvas auth token set <instance> [--url URL] [--token T] | remove <instance>
canvas config add <name> --url URL | list | use <name> | show | remove <name>
canvas context set course|assignment|user|account <id> | show | clear [type]
canvas alias set <name> "<expansion>" | list | delete <name>
canvas cache stats | clear
canvas completion bash|zsh|fish|powershell
canvas repl                                     # interactive shell
canvas mcp start | stream | tools | claude|cursor|vscode enable
canvas skills install [--global] [--agent claude|cursor|…] | path | print
canvas update check | status
```

## Resources and notable actions

| Resource | Actions beyond list/get/create/update/delete |
|---|---|
| `courses` | — (admin listing via `--account-id`) |
| `assignments` | `--bucket upcoming\|overdue\|past…`, `--json file` / `--stdin` bodies |
| `assignment-groups` | — |
| `overrides` | per-assignment date/audience overrides |
| `submissions` | `grade`, `bulk-grade --csv`, `comments`, `add-comment`, `delete-comment` |
| `grades` | `history`, `feed`, `columns {list\|create\|update\|delete\|data}` |
| `modules` | `publish`, `unpublish`, `relock`, `items {list\|get\|create\|update\|delete\|done}` |
| `pages` | `front`, `duplicate`, `revisions`, `revert` |
| `quizzes` | `questions {…}`, `submissions {list\|get}` |
| `discussions` | `entries`, `post`, `reply`, `subscribe`, `unsubscribe` |
| `announcements` | — |
| `users` | `me`, `search <term>` |
| `enrollments` | `accept`, `reject`, `conclude`, `reactivate` |
| `sections` | `crosslist`, `uncrosslist` |
| `groups` | `members {add\|list\|remove}`, `categories {…}` |
| `conversations` | `reply`, `archive`, `star`, `mark-read`, `unread-count` |
| `files` | `upload <path>`, `download <id>`, `quota` |
| `calendar` | `reserve` (appointment slots) |
| `rubrics` | `associate` |
| `outcomes` | `groups`, `link`, `unlink`, `results`, `alignments` |
| `peer-reviews` | — |
| `analytics` | `activity`, `assignments`, `students`, `user`, `department` |
| `accounts` | `sub` (sub-accounts) |
| `admins` | `add`, `remove` |
| `roles` | `activate`, `deactivate` |
| `blueprint` | `associations {add\|list\|remove}`, `sync`, `migrations`, `changes` |
| `content-migrations` | `migrators`, `issues`, `content` |
| `sis-imports` | `errors`, `abort`, `restore` |
| `external-tools` | `launch` |
| `sync` | `course`, `assignments` (cross-instance) |
| `api` | raw `GET\|POST\|PUT\|DELETE\|PATCH /api/v1/…` with `-d`, `-q`, `--paginate` |
| `webhook` | `listen`, `events` |

## Common ID-scoping flags

Most course-scoped commands take `--course-id`; only `assignments list`/`get`
inherit it from `canvas context set course N`. Submission commands additionally
take `--assignment-id` and `--user-id`. Admin commands take `--account-id`.

## Body input (create/update)

Flag-based fields are the norm (`--name`, `--points`, `--due-at …`). Where
supported (e.g. assignments), JSON bodies work too:

```bash
canvas assignments create --course-id 123 --json assignment.json
echo '{"name":"Quiz","points_possible":10}' | canvas assignments create --course-id 123 --stdin
```

## Quick recipes

```bash
# Roster export
canvas users list --course-id 123 --enrollment-type student -o csv > students.csv

# Find ungraded submissions
canvas submissions list --course-id 123 --assignment-id 456 --workflow-state submitted

# Upcoming assignments sorted by due date
canvas assignments list --course-id 123 --bucket upcoming --sort due_at

# Publish all of a course's modules (script over JSON)
canvas modules list --course-id 123 -o json | jq -r '.[].id' \
  | xargs -I{} canvas modules publish --course-id 123 {}

# Cross-instance course copy
canvas sync course prod 12345 staging 67890 --interactive
```
````

## File: skills/canvas-cli/references/output-and-filtering.md
````markdown
# Canvas CLI — output formats and filtering

Loaded on demand by the `canvas-cli` skill. Authoritative docs:
https://jjuanrivvera.github.io/canvas-cli/user-guide/output-formats/

## Formats

```bash
canvas courses list                  # table (default, for humans)
canvas courses list -o json          # for scripts / jq — stable across versions
canvas courses list -o yaml
canvas courses list -o csv           # spreadsheet import
```

Always parse `-o json`; table layout may change between releases. There is no
env var for output format — pass `-o json` on each call.

## Built-in filtering, columns, sorting

Work on every list command and combine freely with any format:

```bash
canvas assignments list --course-id 123 --filter "exam"        # substring, case-insensitive, all fields
canvas assignments list --course-id 123 --columns id,name,due_at,points_possible
canvas assignments list --course-id 123 --sort -due_at         # '-' prefix = descending
canvas assignments list --course-id 123 \
  --filter "exam" --columns id,name,due_at --sort -due_at -o csv > exams.csv
```

`--limit N` caps how many records list commands return — use it on
account-level lists, which can be enormous.

## When to use jq instead

`--filter` is substring-only. For structural queries, use JSON + jq:

```bash
# Field selection
canvas courses list -o json | jq '.[].id'

# Conditional filtering
canvas courses list -o json | jq '.[] | select(.enrollment_term_id == 5)'

# Counting
canvas users list --course-id 123 -o json | jq length

# Reshaping
canvas submissions list --course-id 123 --assignment-id 456 -o json \
  | jq '.[] | {user_id, score, workflow_state}'
```

## Resource-specific list filters

Many list commands have server-side filters that are cheaper than
post-filtering — check `canvas <resource> list --help`. Examples:

```bash
canvas courses list --enrollment-type teacher --state available
canvas courses list --account-id 1 --search "Biology"
canvas assignments list --course-id 123 --bucket upcoming
canvas submissions list --course-id 123 --assignment-id 456 --workflow-state graded
canvas users list --course-id 123 --enrollment-type student
canvas users list --search "john" --limit 50
canvas courses list --include syllabus_body,term       # extra fields from the API
```

## Script hygiene

- `--quiet` suppresses informational messages — only data and errors.
- `--no-cache` when freshness matters (just-written data, polling).
- Exit code is non-zero on failure; check it in scripts.
- `--dry-run` prints the curl equivalent (token redacted; `--show-token` to
  reveal) — ideal for showing the user what a write will do.
````

## File: skills/canvas-cli/SKILL.md
````markdown
---
name: canvas-cli
description: Manage Canvas LMS (https://www.instructure.com/canvas) from the terminal with the `canvas` CLI — courses, assignments, submissions and grading, modules, pages, quizzes, discussions, announcements, users, enrollments, sections, files, and analytics. Use this whenever the user wants to list or create assignments, grade submissions (single or bulk from CSV), manage course content, enroll users, upload or download course files, pull course or student analytics, sync content between Canvas instances, or script any Canvas LMS teaching/administration task.
version: 1.9.0
homepage: https://github.com/jjuanrivvera/canvas-cli
license: MIT
allowed-tools: Bash(canvas:*)
metadata: {"openclaw":{"category":"education","emoji":"🎓","requires":{"bins":["canvas"]},"install":[{"kind":"brew","formula":"jjuanrivvera/canvas-cli/canvas-cli","bins":["canvas"]},{"kind":"go","package":"github.com/jjuanrivvera/canvas-cli/cmd/canvas@latest","bins":["canvas"]}]}}
---

# Canvas CLI

Drive [Canvas LMS](https://www.instructure.com/canvas) through the `canvas`
command-line tool. This skill teaches you how and when to use it.

## Prerequisites

- The `canvas` binary must be on `PATH`. Check with `canvas version`. If
  missing, install it: `brew tap jjuanrivvera/canvas-cli && brew install
  canvas-cli` or `go install github.com/jjuanrivvera/canvas-cli/cmd/canvas@latest`.
- Credentials, one of:
  - **Environment variables** (best for CI/non-interactive): set `CANVAS_URL`
    and `CANVAS_TOKEN`. This takes priority over everything else.
  - **API token**: `canvas auth token set myschool --url
    https://myschool.instructure.com --token 7~...` (token from Canvas →
    Account → Settings → New Access Token).
  - **OAuth**: `canvas auth login --instance https://myschool.instructure.com`
    (opens a browser; add `--mode oob` on headless machines).
- Confirm with `canvas auth status` or `canvas doctor`.

Details on multi-instance setup and precedence:
`references/auth-and-config.md`.

## Golden rules (read before acting)

1. **Preview writes.** Every command accepts `--dry-run`, which prints the
   exact HTTP request as a curl command instead of executing it (tokens
   redacted). For any create/update/delete/grade, run once with `--dry-run`,
   show the user, then run for real. `submissions bulk-grade --dry-run`
   previews the whole batch.
2. **Parse with JSON.** Add `-o json` and pipe to `jq` when you need to read
   values; the default `table` output is for humans.
3. **Resolve IDs live.** Course, assignment, user, section, and module IDs are
   instance-specific — never guess them. Look them up
   (`canvas courses list`, `canvas assignments list --course-id N`,
   `canvas users search "name"`).
4. **Bound big lists.** Account-level lists can be huge; use `--limit N` and
   `--search`/`--filter` instead of dumping everything.
5. **Confirm destructive actions** (`delete`, `conclude`) with the user before
   running them, and prefer `--dry-run` first.
6. **Set context for a working session.** `canvas context set course 12345`
   makes `--course-id` implicit for `assignments list`/`assignments get` (other
   commands still need explicit flags); explicit flags always override it.
   Check what's active with `canvas context show`.
7. **Mind the instance.** With multiple configured instances, verify which one
   is active (`canvas config list`) before writing; switch with
   `canvas config use <name>` or per-command `--instance`.
8. **Prefer `canvas` over curl.** Never hand-roll `curl` against the Canvas
   API when this CLI is available: it handles auth, pagination, rate limiting,
   and retries for you. For endpoints without a dedicated command, use
   `canvas api` (see the raw API escape hatch below).

## Workflow: auth → discover → act → verify

```bash
canvas doctor                          # 1. verify install, auth, connectivity
canvas courses list -o json            # 2. find real IDs
canvas <resource> --help               # 3. discover actions & flags
canvas assignments create --course-id 123 --name "Quiz 1" --points 100 --dry-run   # 4. preview
canvas assignments create --course-id 123 --name "Quiz 1" --points 100             #    act
canvas assignments list --course-id 123 --filter "Quiz 1"                          # 5. verify
```

## Command map

`canvas <resource> <action>` — most resources support
`list|get|create|update|delete` plus resource-specific actions. Main resources:

| Area | Resources |
|---|---|
| Teaching | `courses`, `assignments`, `assignment-groups`, `modules`, `pages`, `quizzes` (incl. `reports`, `statistics`, `question-groups`, `ip-filters`), `discussions`, `announcements`, `rubrics`, `rubric-associations`, `outcomes`, `overrides`, `peer-reviews`, `polls` |
| Grading | `submissions` (`grade`, `bulk-grade`, `add-comment`), `grades`, `grading-periods`, `grading-standards`, `grading-period-sets`, `live-assessments` |
| People | `users`, `enrollments`, `sections`, `groups` (`memberships`, `categories`), `conversations`, `comm-channels`, `observees`, `appointment-groups` |
| Content & files | `files`, `folders`, `calendar`, `content-migrations`, `content-exports`, `content-shares`, `blueprint`, `course-pacing`, `blackout-dates`, `media`, `eportfolios` |
| Personal | `favorites`, `bookmarks`, `course-nicknames`, `planner`, `history` |
| Admin | `accounts`, `admins`, `roles`, `analytics`, `sis-imports`, `external-tools`, `auth-providers`, `csp-settings`, `account-notifications`, `account-reports`, `enrollment-terms`, `developer-keys`, `audit` |
| Utility | `api` (raw requests), `sync`, `context`, `alias`, `cache`, `doctor`, `mcp`, `repl`/`shell`, `webhook`, `jwts`, `progress` |

The CLI has ~93 command groups covering most of the Canvas REST API. The table
above is a guide, not the full list — **always discover the real surface with
`canvas --help` and `canvas <resource> --help`** rather than assuming a command
exists. Most resources that exist under a course also exist under a group or
user context via `--group-id`/`--user-id` (e.g. discussions, pages, files,
folders, content-migrations). A condensed cheatsheet ships in
`references/canvas-commands.md`.

```bash
# Courses
canvas courses list                              # your enrolled courses
canvas courses list --account-id 1 --search "Biology"   # admin: account courses
canvas courses get 123 -o json | jq '{id,name,course_code}'

# Assignments
canvas assignments list --course-id 123 --bucket upcoming
canvas assignments create --course-id 123 --name "Essay" --points 50 \
  --due-at "2026-08-01T23:59:00Z" --grading-type points
echo '{"name":"Quiz 1","points_possible":100}' | canvas assignments create --course-id 123 --stdin

# Users & enrollments
canvas users search "john doe"
canvas users list --course-id 123 --enrollment-type student
canvas enrollments create --course-id 123 --user-id 456 --type StudentEnrollment --state active

# Modules (content structure)
canvas modules create --course-id 123 --name "Week 1"
canvas modules items create --course-id 123 --module-id 9 --type Assignment --content-id 456
canvas modules publish --course-id 123 9
```

## Output: formats, filtering, columns, sorting

Global flags work on every command:

```bash
canvas courses list -o json | jq '.[].id'        # json | yaml | csv | table
canvas assignments list --course-id 123 --filter "exam"      # substring, all fields
canvas assignments list --course-id 123 --columns id,name,due_at,points_possible
canvas assignments list --course-id 123 --sort -due_at       # '-' prefix = descending
canvas users list --course-id 123 -o csv > roster.csv
canvas users list --account-id 1 --limit 100                 # cap result count
```

Use built-in `--filter` for simple matching and `-o json | jq` for anything
structural. Details: `references/output-and-filtering.md`.

## Workflow: grade a submission

```bash
# Find who/what to grade
canvas assignments list --course-id 123 --filter "Essay"
canvas submissions list --course-id 123 --assignment-id 456 --workflow-state submitted

# Grade one submission (score, letter grade, or excuse)
canvas submissions grade --course-id 123 --assignment-id 456 --user-id 789 \
  --score 95 --comment "Great work"

# Verify
canvas submissions get --course-id 123 --assignment-id 456 --user-id 789 -o json
```

## Workflow: bulk grading from CSV

CSV columns: `user_id,assignment_id,score,comment`.

```bash
canvas submissions bulk-grade --course-id 123 --csv-file grades.csv --dry-run   # preview every change
canvas submissions bulk-grade --course-id 123 --csv-file grades.csv             # apply (concurrent)
canvas grades history --course-id 123                                      # audit afterwards
```

## Workflow: publish course content

```bash
canvas pages create --course-id 123 --title "Syllabus" --body "<p>…</p>" --published
canvas announcements create --course-id 123 --title "Welcome" --message "Class starts Monday"
canvas quizzes create --course-id 123 --title "Midterm" --quiz-type assignment --time-limit 60
canvas discussions create --course-id 123 --title "Week 1 discussion"
canvas files upload syllabus.pdf --course-id 123
```

## Sync between instances

`canvas sync` copies content across configured instances (e.g. staging →
production). Both instances must exist in config and be authenticated.

```bash
canvas sync assignments prod 12345 staging 67890
canvas sync course prod 12345 staging 67890 --interactive   # interactive conflict resolution
```

## Raw API escape hatch

For endpoints without a dedicated command:

```bash
canvas api GET /api/v1/courses/123/todo
canvas api POST /api/v1/accounts/1/courses -d '{"course":{"name":"New Course"}}'
canvas api GET /api/v1/users -q "search_term=john" --paginate
```

`--dry-run` works here too — use it to show the user the exact request.

**Gotcha:** `canvas api` wraps the response in an envelope — the payload is
under `.body`, not at the top level:

```bash
# {"body": [...actual data...], "status_code": 200}
canvas api GET /api/v1/courses/123/tabs -o json | jq '.body'      # the data
canvas api GET /api/v1/courses/123/tabs -o json | jq '.body[0]'  # first item
```

Dedicated commands (`canvas modules list`, …) return the data directly,
without this wrapper.

## MCP server mode

The same binary is an MCP server exposing each command as a typed tool — use
it when a client wants structured tools instead of shell:

```bash
canvas mcp start            # STDIO MCP server
canvas mcp stream --port 8080   # HTTP
canvas mcp claude enable    # auto-configure Claude Desktop (also: cursor, vscode)
```

The skill (shell) and MCP modes can coexist; prefer the shell when you can run
commands directly.

## Errors & troubleshooting

- `canvas doctor` diagnoses install/auth/connectivity in one shot.
- `401` → re-auth (`canvas auth login` / check `CANVAS_TOKEN`); `403` → missing
  permission or masquerade (`--as-user`) not allowed; `404` → wrong ID or wrong
  instance.
- Rate limits are handled automatically (adaptive throttling + retries); for
  long batch jobs in env-auth mode you can tune `CANVAS_REQUESTS_PER_SEC`.
- Stale data? Responses are cached — add `--no-cache` or run
  `canvas cache clear`.
- Add `-v/--verbose` to see request logging; `--quiet` for clean script output.

## More

Full docs: https://jjuanrivvera.github.io/canvas-cli/ . Condensed references
ship alongside this skill in `references/canvas-commands.md`,
`references/auth-and-config.md`, and `references/output-and-filtering.md`.
````

## File: CHANGELOG.md
````markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This file is the single source of truth; `docs/changelog.md` is a copy kept in
sync by `make docs-gen` and the documentation workflow.

## [Unreleased]

### Planned

- Canvas Studio integration
- GraphQL API support

## [1.13.0] - 2026-08-05

### Added

- `canvas api get <PATH>`: a GET-only sibling of `canvas api`, exported to MCP as
  the `canvas_api_get` tool with `readOnlyHint: true`. It gives broad Canvas read
  coverage from a single tool schema, so read-only MCP clients no longer need to
  allowlist hundreds of individual read tools. The general `canvas api` escape
  hatch (any HTTP verb) stays unannotated and is still filtered out by read-only
  clients. ([#60](https://github.com/jjuanrivvera/canvas-cli/issues/60))
- `canvas mcp start --readonly`: serve only read-only tools. The flag exposes the
  commands annotated `readOnlyHint: true` and drops the rest (writes and the
  general `api` tool), so `canvas_api_get` is served in place of `canvas_api`.
  This moves the read-only boundary into the binary, holding even for MCP clients
  that do not filter by annotation themselves. ([#60](https://github.com/jjuanrivvera/canvas-cli/issues/60))

## [1.12.0] - 2026-08-05

### Added

- MCP tools now emit per-tool annotations (`readOnlyHint`, `destructiveHint`,
  `openWorldHint`). Clients that enforce a read-only session allow a tool only
  when `readOnlyHint` is strictly `true` and treat a missing annotation as a
  write, so previously every tool was filtered out and the whole server was
  dropped. 247 of 533 tools are now marked read-only. ([#58](https://github.com/jjuanrivvera/canvas-cli/issues/58))

  The hints are derived from the same classification `canvas agent guard` uses,
  so a tool cannot advertise itself as read-only while the guard gates it as a
  write. `canvas api` and local commands that mutate state (`auth login`,
  `config account`, `cache clear`, …) are deliberately left unannotated and are
  therefore dropped by read-only clients.

## [1.11.2] - 2026-08-04

### Fixed

- `external-tools list`: account-level tools whose placements carry
  `required_permissions` as a comma-separated string (instead of an array) no
  longer crash the whole list. A new `CommaSeparatedList` type accepts both the
  array and comma-separated-string shapes. Additionally, a single element that
  fails to decode is now logged and skipped rather than discarding the entire
  page. ([#55](https://github.com/jjuanrivvera/canvas-cli/issues/55))
- `enrollments create` (and every other command that decodes a single object
  from a create/update) no longer fails when Canvas wraps the response in an
  array — some deployments return `[]` or `[obj]` instead of `obj`. Response
  decoding now tolerates an array-wrapped single object across all resources
  (uses the first element; an empty array on success is treated as success).
  ([#56](https://github.com/jjuanrivvera/canvas-cli/issues/56))

## [1.11.1] - 2026-07-30

### Changed

- `canvas doctor`: the command now resolves its diagnostics runner through an
  injectable `diagnostics.Runner` seam (`newDoctorRunner`) instead of calling
  `diagnostics.New` directly. Runtime behavior is unchanged for users; the seam
  lets the command tests drive deterministic fake reports so
  `go test ./commands -run TestDoctorCmd` no longer depends on live network,
  host permissions, or real credentials — and no longer skips under CI. The
  real end-to-end path remains covered by an opt-in smoke test gated behind
  `CANVAS_DOCTOR_LIVE=1`. ([#28](https://github.com/jjuanrivvera/canvas-cli/issues/28))

## [1.11.0] - 2026-07-13

### Added

- `auth login --public-client`: secret-less OAuth for Canvas developer keys provisioned with
  `client_type = "public"` — the token exchange and refresh are protected by PKCE only, and the
  request omits `client_secret` entirely. Canvas validates PKCE on hosted instances since the
  March 2026 release; public-client keys must currently be provisioned by Instructure (they are
  not self-service in the Developer Keys UI). Instances persist this as `public_client: true`
  in `config.yaml`. ([#48](https://github.com/jjuanrivvera/canvas-cli/issues/48),
  [#51](https://github.com/jjuanrivvera/canvas-cli/issues/51))

### Documentation

- Authentication guide: new "Public Clients (PKCE Only, No Secret)" section, and corrected the
  OAuth setup instructions — the CLI never shipped embedded OAuth credentials; a developer key
  is required.

## [1.10.5] - 2026-07-11

### Security

- `auth login` now reads secrets with a **hidden** prompt instead of `fmt.Scanln` — the API
  access token, the OAuth client secret, and the OAuth authorization code. Previously they were
  echoed to the terminal in plaintext (landing in scrollback) and `fmt.Scanln` could stall on a
  long pasted token. Non-secret inputs (client ID, y/n confirmations) are unchanged.

## [1.10.4] - 2026-07-11

### Added

- One-line install script for macOS/Linux (checksum-verified):
  `curl -fsSL https://raw.githubusercontent.com/jjuanrivvera/canvas-cli/main/install.sh | sh`.

### Security

- Build with Go 1.25.12 to clear GO-2026-5856 (privacy leak in `crypto/tls`
  Encrypted Client Hello).

## [1.10.3] - 2026-07-10

### Added

- Scoop (Windows) packaging via `jjuanrivvera/scoop-canvas-cli`, documented in the
  README alongside Homebrew, Go, Docker, and binary installs.

## [1.10.2] - 2026-07-02

### Fixed

- **`agent guard` hook hardening.** The generated PreToolUse hook missed several
  bypasses: path-invoked binaries (`./bin/canvas`, `/usr/local/bin/canvas`) were
  not matched; a shell separator glued to a no-arg irreversible verb
  (`canvas favorites courses reset;true`) slipped the trailing boundary; and the
  no-jq fallback could fail open because the compact JSON payload glues the
  command to its key. All three are fixed, and `sync assignments` (whose leaf
  collides with the `analytics assignments` read verb) is now correctly gated as
  a write. A different binary that merely ends in `canvas` is still not matched.
- Cleared pre-existing lint debt surfaced by the current golangci-lint
  (`reflect.Ptr` → `reflect.Pointer`; `WriteString(fmt.Sprintf(...))` →
  `fmt.Fprintf(...)` in speccheck). No behavior change.

## [1.10.1] - 2026-07-02

### Fixed

- **Documentation audited against the shipped CLI**: repaired examples that no
  longer ran — `submissions grade-batch` → `bulk-grade --csv-file` with the
  correct `user_id,assignment_id,score,comment` CSV columns, `submissions
  grade` flag usage (`--user-id`/`--score`/`--posted-grade`, no positional id),
  `enrollments create --user-id`/`--type`, positional `sync course` and
  `users search`, `assignments create --group-id`, and `config account
  <instance> <account-id>`. Corrected stale numbers (93 command groups — the
  v1.10.0 note below originally overcounted 46→93 as 52→98 — 530+ MCP tools,
  the 80% CI coverage gate) and removed the nonexistent
  `CANVAS_OUTPUT`/`CANVAS_NO_CACHE` env vars from docs and the bundled skill
  (`CANVAS_CLI_MACHINE_ID` is documented instead).
- **`canvas context` help text** no longer claims every command consumes the
  stored context: only `assignments list`/`assignments get` read the course
  context today. The user guide, best practices, and bundled agent skill now
  document the same behavior.
- **Agent-guard docs**: dropped `status` from the documented read allowlist to
  match the code's `canvasReadVerbs`; the Agent Safety guide is now linked
  from the docs landing pages.
- **Contributor docs** reflect the current repo: no `pkg/` directory or VCR
  cassettes, `make check` and the spec targets documented, architecture page
  updated with the real package layout and the spec-compliance harness.

## [1.10.0] - 2026-06-23

### Added

- **Agent safety guard** (`canvas agent guard --host claude-code|codex|opencode`):
  generates AI-agent safety config — permission rules plus a `PreToolUse` hook —
  that hard-blocks irreversible Canvas operations (delete, conclude, crosslist,
  cancel, close, merge, split, reset, …) and requires approval for ordinary
  writes, derived from the live command tree. Classification is fail-safe: only
  an explicit read allowlist stays allowed, so unrecognized/future verbs are
  gated rather than slipping through. Rules are emitted as exact command paths
  and exact MCP tool names; the hook matches the subcommand at the command
  position (no false positives from verb words in arguments) and covers the
  `canvas api` raw escape hatch (incl. PATCH). `--write` installs the config
  under the project root without overwriting existing files. See the
  [Agent Safety guide](https://jjuanrivvera.github.io/canvas-cli/user-guide/agent-safety/).
- **API coverage raised to 80%** (876 of 1086 documented endpoint patterns,
  method-aware): added ~100 service-layer endpoints across assignments,
  quizzes, modules, outcomes, outcome-imports, courses, sections,
  content-migrations, files, folders, pages, discussions, blueprint, accounts,
  and assignment-groups, each validated by the contract test and covered with
  assertion-rich tests (method + path + request body + parsed response fields).
- **Accurate, method-aware coverage measurement**: the `speccheck` coverage
  harvester now pairs each path with its HTTP verb and resolves context-path
  helper functions, so coverage is counted at (method, path) granularity on
  both sides (previously mismatched-granularity).
- **API spec-compliance harness**: CLI endpoint paths are now validated in CI
  against Canvas's official API spec (Swagger 1.2), committed under
  `testdata/spec/`. A network-free contract test fails the build on any path
  Canvas doesn't document. `make spec-sync` refreshes the manifest from a live
  Canvas host; `make spec-coverage` reports the gap. See
  [API Coverage](https://jjuanrivvera.github.io/canvas-cli/development/api-coverage/).
- **Major API coverage expansion**: 31% → 67% of Canvas's documented endpoints
  (46 → 93 command groups). New command groups include `polls`,
  `appointment-groups`, `folders`, `favorites`, `bookmarks`, `course-nicknames`,
  `observees`, `comm-channels`, `content-shares`, `audit`, `media`,
  `conferences`, `collaborations`, `eportfolios`, `brand`, `jwts`, `progress`,
  `history`, account administration (`auth-providers`, `csp-settings`,
  `account-reports`, `enrollment-terms`, `developer-keys`,
  `grading-period-sets`), grading (`grading-periods`, `grading-standards`,
  `rubric-associations`, `live-assessments`), and content management
  (`content-exports`, `blackout-dates`, `course-pacing`).
- **Full quizzes surface**: reports, statistics, extensions, IP filters,
  question groups, and submission questions.
- **Multi-context support**: discussions, pages, files, folders, and
  content-migrations now work under group and user contexts via `--group-id`
  and `--user-id`, in addition to courses.

### Fixed

- **Response envelope parsing**: many newly added endpoints decoded Canvas's
  named-array envelopes (e.g. `{"polls":[...]}`, `{"events":[...]}`) into bare
  Go types and would fail against a live Canvas; all corrected and now verified
  by shape-asserting tests (polls, audit logs, account calendars, SIS imports,
  quiz submission questions, notification preferences).
- **Request construction**: `csp-settings` domain removal no longer discards
  its argument; `files set-usage-rights` no longer drops all but the last ID;
  group file uploads target `/groups/:id/files` instead of the folder endpoint;
  account/grading param bodies use proper nested JSON instead of unparsed
  bracketed keys; a deliberate `false` for weighted grading periods is no
  longer dropped.
- **Field/return types**: `course-pacing` root-account field and
  `user-features` enabled-list return type corrected.
- Earlier path fixes surfaced by the harness: content-migrations selective
  import (`/selective_data`), last-attended (user-scoped), and quiz IP filters
  (require `:quiz_id`).

### Changed

- CI coverage accounting is HTTP-method-aware (a path isn't counted implemented
  just because the CLI has a different verb on it).
- AGENTS.md documents the spec-compliance + coverage workflow; the bundled
  agent skill's command map covers the expanded surface.

## [1.9.1] - 2026-06-11

### Security

- The OAuth callback server and webhook listener now set a read-header
  timeout (slowloris hardening)
- gosec static analysis is now a blocking CI gate (283-finding backlog
  resolved: real fixes plus justified suppressions)
- Self-update state directory permissions tightened

### Changed

- Releases are built with current GitHub Actions runtimes (Node 24);
  cosign stays on the v2 line so published verification instructions
  keep working
- Dependabot now keeps GitHub Actions and Go dependencies current

### Internal

- New binary-level integration test suite (`make test-integration`)
  exercising the compiled CLI against a mock Canvas server
- New `make check` target running every CI gate locally
- Removed the misleading legacy command test framework; deduplicated
  ~200 test client constructions behind a shared helper

## [1.9.0] - 2026-06-10

### Added

- **Docker image**: releases now publish `ghcr.io/jjuanrivvera/canvas-cli` (distroless, multi-tag)
- **Signed releases**: checksums are signed keylessly with cosign (Sigstore) and archives ship SBOMs
- **AI agent skill**: bundled skill for Claude Code, Cursor, and other agents — install via `canvas skills install`, `npx skills add jjuanrivvera/canvas-cli`, or the Claude Code plugin marketplace
- Confirmation prompt and `--force` flag for `submissions delete-comment`
- `--json-file`/`--csv-file` input flags (the ambiguous `--json`/`--csv` input flags are deprecated but still work)
- `doctor` now honors the global `-o json` output flag

### Fixed

- **Batch assignment sync no longer panics** on courses with assignments
- Retried POST/PUT requests resend the full body instead of an empty one
- `assignments bulk-update` sends `assignment_ids` in a format Canvas accepts
- User assignments endpoint requested the wrong path (user ID was used as course ID)
- `bulk-grade` progress ID is now parsed from the Canvas response
- Ctrl+C now cancels in-flight course validation and sync operations
- Rate-limit bookkeeping no longer races when quota is updated concurrently
- DELETE responses are drained and closed, restoring HTTP connection reuse
- Pagination is guarded against servers that repeat the same `next` link
- 429 responses now honor the `Retry-After` header
- File upload confirmation works for OAuth (auto-refreshed) sessions

### Security

- Static API tokens from `auth token set` are stored in the OS keyring/encrypted store instead of plaintext `config.yaml` (existing configs keep working)
- File downloads sanitize server-supplied filenames (path-traversal protection)
- Self-update aborts when a release is missing `checksums.txt` (fail closed)
- `http://` instance URLs are rejected for non-loopback hosts
- Webhook listener defaults to `127.0.0.1` and warns when signature verification is not configured
- OAuth callback server binds to loopback only
- Config and REPL history directories are created with `0700` permissions

### Changed

- Delete confirmations are unified: all destructive commands accept `y`/`yes` and honor `--dry-run`
- `shell` is now an alias of `repl` (single REPL command)
- Remaining commands migrated to the options-struct pattern (`api`, `cache`, `sync`, `telemetry`, `repl`, `completion`)
- CI pins Go via `go.mod`, blocks on `govulncheck`, and pins security scanners
- A warning is printed when `CANVAS_URL`/`CANVAS_TOKEN` env vars override an explicit `--instance` flag

## [1.8.1] - 2026-06-09

### Changed

- **Test Quality**: Raised overall test coverage to ~82% and added a CI coverage gate (#31)
- **CI Stability**: Stabilized cross-platform CI runs (ubuntu/macos/windows) (#31)

### Documentation

- Improved MCP setup and auth/environment documentation (#29)
- Added CI, pkg.go.dev, codecov, and Ask DeepWiki badges (#30)

## [1.8.0] - 2026-04-29

### Added

- **MCP Server Mode**: Run Canvas CLI as a Model Context Protocol server for AI tools and editors.
  - Added `canvas mcp` command group for server startup, tool export, and editor integration.
  - Added MCP command discovery and schema generation via `ophis`.
- **CLI Runtime Utilities**: Added shared terminal and parsing utilities.
  - Added signal-aware command execution via `ExecuteContext`.
  - Added shell-style alias parsing support with `internal/shellparse`.

### Changed

- **Toolchain Baseline**: Updated minimum Go version to 1.25.0 and aligned CI accordingly.
- **Structured Output Behavior**: Improved command output helpers to better preserve parseable JSON/YAML/CSV in scripts.

### Fixed

- **Canvas Soft Error Detection**: Detect API error bodies returned with HTTP 200 and surface them as errors instead of successful responses.
- **Safety for API Command Flags**: Removed global `-q` shorthand from `--quiet` to avoid collision with `canvas api --query/-q`.

## [1.7.0] - 2026-01-25

### Added

- **Command Aliases**: Create shortcuts for frequently used commands
  - `canvas alias set <name> "<command>"` - Create an alias
  - `canvas alias list` - List all aliases
  - `canvas alias delete <name>` - Remove an alias
  - Aliases are stored in config and expand at runtime

- **Context Management**: Set default values for common flags
  - `canvas context set <type> <id>` - Set course, assignment, user, or account context
  - `canvas context show` - Display current context
  - `canvas context clear [type]` - Clear all or specific context
  - Commands automatically use context when flags aren't provided

- **Output Filtering**: Filter and sort command output
  - `--filter <text>` - Filter results by text (case-insensitive, searches all fields)
  - `--columns <list>` - Select specific columns to display
  - `--sort <field>` - Sort by field (prefix with `-` for descending)
  - Works with all output formats (table, JSON, YAML, CSV)

- **Enhanced Dry-Run Mode**: Preview destructive operations with details
  - Delete commands show resource details before confirmation
  - Update commands show what would change
  - Works with `--dry-run` and `--force` flags

- **Curl Command Output**: See equivalent curl commands with `--dry-run`
  - Useful for debugging and learning the Canvas API
  - Token redacted by default, use `--show-token` to include

- **Aggressive Auto-Update**: Automatic update checking
  - `canvas update enable` - Enable automatic update checks
  - `canvas update disable` - Disable automatic update checks
  - `canvas update check` - Manually check for updates
  - `canvas update status` - Show update settings

### Changed

- Improved CLI UX inspired by modern tools (gh, kubectl, stripe-cli)
- Documentation updated with new feature guides

## [1.6.1] - 2026-01-19

### Fixed

- Changed command lifecycle logs to DEBUG level to keep normal output clean

## [1.6.0] - 2026-01-19

### Added

- **Command Infrastructure Packages** (#18)
  - `commands/internal/options` package with an option-struct validation framework
  - `commands/internal/logging` package with structured command logging
  - `commands/internal/testing` package for command integration tests

### Changed

- Began migrating commands from package-level flag variables to the options-struct pattern

## [1.5.3] - 2026-01-15

### Added

- **Default Account ID**: Configure a default account so account-scoped commands don't require `--account-id` every time (#17)
- **Global `--limit` Flag**: Limit the number of results for any list operation (#17)

### Fixed

- Assorted Canvas API request fixes (#17)

## [1.5.2] - 2026-01-14

### Added

- **Per-instance API Token Authentication**: New alternative to OAuth for simpler authentication
  - `canvas auth token set <instance>` - Configure API token for an instance
  - `canvas auth token remove <instance>` - Remove API token from an instance
  - Tokens stored in config file, can be mixed with OAuth per-instance
- **User-Agent Header**: All API requests now include `User-Agent: canvas-cli/VERSION`
  - Required by Canvas API (enforcement coming soon per Canvas changelog)
  - Includes version for debugging and analytics
- **Auth Status Improvements**: `canvas auth status` now shows authentication type (token/oauth/none)
- **Instance Helper Methods**: `HasToken()`, `HasOAuth()`, `AuthType()` for config

### Changed

- Token authentication takes precedence over OAuth when both are configured for an instance
- Improved error messages for authentication failures

## [1.5.1] - 2026-01-14

### Fixed

- Wrapped command examples in code blocks in the generated CLI reference documentation

## [1.5.0] - 2026-01-14

### Added

#### 70+ New Write Commands
This release adds comprehensive write command support across all Canvas API resources:

##### Account Administration
- `canvas admins add` - Add account administrator
- `canvas admins list` - List account administrators
- `canvas admins remove` - Remove account administrator
- `canvas roles create` - Create custom role
- `canvas roles update` - Update role permissions
- `canvas roles delete` - Delete custom role
- `canvas roles list` - List account roles

##### Analytics
- `canvas analytics activity` - View course activity
- `canvas analytics assignments` - View assignment statistics
- `canvas analytics department` - View department-level analytics
- `canvas analytics students` - View student analytics
- `canvas analytics user` - View user-specific analytics

##### Assignment Groups
- `canvas assignment-groups list` - List assignment groups
- `canvas assignment-groups get` - Get assignment group details
- `canvas assignment-groups create` - Create assignment group
- `canvas assignment-groups update` - Update assignment group
- `canvas assignment-groups delete` - Delete assignment group

##### Blueprint Courses
- `canvas blueprint get` - Get blueprint details
- `canvas blueprint sync` - Sync blueprint to associated courses
- `canvas blueprint changes` - View unsynced changes
- `canvas blueprint associations list` - List associated courses
- `canvas blueprint associations add` - Add course associations
- `canvas blueprint associations remove` - Remove associations
- `canvas blueprint migrations list` - List sync history
- `canvas blueprint migrations get` - Get migration details

##### Content Migrations
- `canvas content-migrations list` - List migrations
- `canvas content-migrations get` - Get migration details
- `canvas content-migrations create` - Start content migration
- `canvas content-migrations issues` - View migration issues

##### Conversations (Inbox)
- `canvas conversations list` - List conversations
- `canvas conversations get` - Get conversation details
- `canvas conversations create` - Create new conversation
- `canvas conversations reply` - Reply to conversation
- `canvas conversations forward` - Forward conversation
- `canvas conversations add-recipients` - Add recipients
- `canvas conversations mark-read` - Mark as read
- `canvas conversations mark-unread` - Mark as unread
- `canvas conversations archive` - Archive conversation
- `canvas conversations unarchive` - Unarchive conversation
- `canvas conversations star` - Star conversation
- `canvas conversations unstar` - Unstar conversation
- `canvas conversations delete` - Delete conversation
- `canvas conversations batch-update` - Bulk update conversations

##### Courses
- `canvas courses create` - Create new course
- `canvas courses update` - Update course
- `canvas courses delete` - Delete/conclude course

##### External Tools (LTI)
- `canvas external-tools list` - List external tools
- `canvas external-tools get` - Get tool details
- `canvas external-tools create` - Create external tool
- `canvas external-tools update` - Update external tool
- `canvas external-tools delete` - Delete external tool
- `canvas external-tools sessionless-launch` - Get sessionless launch URL

##### Grades & Gradebook
- `canvas grades summary` - View grade summary
- `canvas grades history` - View grade history
- `canvas grades bulk-update` - Bulk update grades
- `canvas grades final` - Get final grades
- `canvas grades current` - Get current grades

##### Groups
- `canvas groups list` - List groups
- `canvas groups get` - Get group details
- `canvas groups create` - Create group
- `canvas groups update` - Update group
- `canvas groups delete` - Delete group
- `canvas groups users` - List group members
- `canvas groups invite` - Invite users to group
- `canvas groups join` - Join a group
- `canvas groups leave` - Leave a group
- `canvas groups categories list` - List group categories
- `canvas groups categories create` - Create category
- `canvas groups categories update` - Update category
- `canvas groups categories delete` - Delete category

##### Learning Outcomes
- `canvas outcomes list` - List outcomes
- `canvas outcomes get` - Get outcome details
- `canvas outcomes create` - Create learning outcome
- `canvas outcomes update` - Update outcome
- `canvas outcomes delete` - Delete outcome
- `canvas outcomes groups list` - List outcome groups
- `canvas outcomes groups get` - Get group details
- `canvas outcomes groups create` - Create outcome group
- `canvas outcomes groups update` - Update group
- `canvas outcomes groups delete` - Delete group
- `canvas outcomes import` - Import outcomes
- `canvas outcomes alignments` - View outcome alignments
- `canvas outcomes results` - View outcome results

##### Assignment Overrides
- `canvas overrides list` - List assignment overrides
- `canvas overrides get` - Get override details
- `canvas overrides create` - Create date/student override
- `canvas overrides update` - Update override
- `canvas overrides delete` - Delete override
- `canvas overrides batch-create` - Bulk create overrides
- `canvas overrides batch-update` - Bulk update overrides

##### Peer Reviews
- `canvas peer-reviews list` - List peer reviews
- `canvas peer-reviews create` - Assign peer review
- `canvas peer-reviews delete` - Remove peer review assignment

##### Quizzes (Classic Quizzes)
- `canvas quizzes list` - List quizzes
- `canvas quizzes get` - Get quiz details
- `canvas quizzes create` - Create quiz
- `canvas quizzes update` - Update quiz
- `canvas quizzes delete` - Delete quiz
- `canvas quizzes reorder` - Reorder quiz questions
- `canvas quizzes validate-token` - Validate access code
- `canvas quizzes questions list` - List quiz questions
- `canvas quizzes questions get` - Get question details
- `canvas quizzes questions create` - Create question
- `canvas quizzes questions update` - Update question
- `canvas quizzes questions delete` - Delete question
- `canvas quizzes submissions list` - List quiz submissions
- `canvas quizzes submissions get` - Get submission details
- `canvas quizzes submissions start` - Start quiz attempt
- `canvas quizzes submissions complete` - Complete quiz attempt

##### Rubrics
- `canvas rubrics list` - List rubrics
- `canvas rubrics get` - Get rubric details
- `canvas rubrics create` - Create rubric
- `canvas rubrics update` - Update rubric
- `canvas rubrics delete` - Delete rubric
- `canvas rubrics associations` - List rubric associations
- `canvas rubrics associate` - Associate rubric with assignment
- `canvas rubrics assessments` - View rubric assessments

##### Course Sections
- `canvas sections list` - List course sections
- `canvas sections get` - Get section details
- `canvas sections create` - Create section
- `canvas sections update` - Update section
- `canvas sections delete` - Delete section
- `canvas sections crosslist` - Cross-list section
- `canvas sections uncrosslist` - Remove cross-listing

##### SIS Imports
- `canvas sis-imports list` - List import history
- `canvas sis-imports get` - Get import details
- `canvas sis-imports create` - Start SIS import
- `canvas sis-imports abort` - Abort running import
- `canvas sis-imports restore` - Restore deleted items
- `canvas sis-imports errors` - View import errors

##### Raw API Access
- `canvas api` - Make raw API requests to any Canvas endpoint

##### Modules Improvements
- `canvas modules publish` - Publish module (convenience)
- `canvas modules unpublish` - Unpublish module (convenience)
- `canvas modules items update` - Update module item (was missing)

##### Enrollments Improvements
- `canvas enrollments create` - Create enrollment
- `canvas enrollments update` - Update enrollment state
- `canvas enrollments delete` - Delete/deactivate enrollment
- `canvas enrollments accept` - Accept enrollment invitation
- `canvas enrollments reject` - Reject enrollment invitation
- `canvas enrollments reactivate` - Reactivate enrollment

##### Submissions Improvements
- `canvas submissions update` - Update submission
- `canvas submissions summary` - Get submission summary

#### Webhook JWT Verification (Canvas Data Services)
- **JWT verification support**: Use `--canvas-data-services` flag for Instructure-hosted Canvas instances that use Canvas Data Services
- **Custom JWK endpoints**: Use `--jwks-url` for custom JWK endpoints
- **Automatic JWK caching**: Public keys are cached for 1 hour and refreshed automatically
- **Fallback mode**: Both JWT and HMAC verification can be enabled simultaneously

### Fixed

#### UX Improvements
- **JSON output for write commands**: All create/update/delete commands now properly support `-o json` output format
- **Rubrics response parsing**: Fixed issue where rubrics were wrapped in `{rubric: {...}}` envelope
- **Conversations JSON keys**: Fixed duplicate array bracket suffix `[]` in JSON request keys
- **Zero date display**: Now shows "Not set" instead of "0001-01-01 00:00:00" for unset dates
- **Empty collections**: Hidden in output instead of showing `map[]` or `[]`
- **404 error messages**: Now include descriptive text explaining what resource was not found
- **Nested struct display**: New `formatStructCompact()` for clean display of complex nested structures

### Changed
- External tools delete now requires `--force` flag for confirmation
- Courses create now accepts `--account` as alias for `--account-id`

## [1.4.0] - 2026-01-13

### Added

#### Authentication Improvements
- **Automatic OAuth Token Refresh**: Access tokens are now automatically refreshed using refresh tokens when they expire, eliminating the need for manual re-authentication
- **Instance Config Lookup**: `canvas auth login --instance <name>` now automatically loads the URL and OAuth credentials from your config file
- **Positional Instance Name**: `canvas config add` now accepts instance name as a positional argument: `canvas config add production --url https://canvas.example.com`

#### Table Output Improvements
- **Compact Table Output**: Default table output now shows only key fields for cleaner display
- **Verbose Mode**: Use `-v/--verbose` flag to see all fields in table output
- **Improved Field Selection**: Key fields are optimized for each resource type (Course, User, Assignment, etc.)
- **Instance Name Support**: The `--instance` flag now accepts instance names (not just URLs)

### Changed
- `canvas config add <name> --url <url>` syntax replaces `canvas config add --name <name> --url <url>`
- Table formatter now uses structured formatters instead of custom display functions
- Removed "Found X items:" messages in compact (non-verbose) mode

### Fixed
- Pre-commit hook now includes golangci-lint for catching lint issues before push
- Removed unused display functions that were causing lint warnings
- Documentation updated to reflect correct CLI syntax and behavior

### Developer Experience
- **Pre-commit Linting**: Added golangci-lint to pre-commit hook for early lint error detection
- **Documentation Accuracy**: Fixed documentation to match actual CLI behavior (sync command syntax, environment variables, flags)

## [1.3.1] - 2026-01-13

### Fixed

- Corrected ldflags variable names so released binaries report the right version (`main.Version`, `main.Commit`, `main.BuildDate`)

## [1.3.0] - 2026-01-13

### Added

- **GoReleaser Configuration**: Automated multi-platform release builds with checksums (#7)
- **Homebrew Tap**: Install via `brew tap jjuanrivvera/canvas-cli && brew install canvas-cli` (#7)

### Fixed

- Corrected import grouping for the goimports linter
- Removed broken SPECIFICATION.md link from the changelog
- Removed conflicting `goreleaser.yml` config file

## [1.2.1] - 2026-01-13

### Fixed

- Addressed lint and security issues from PR review
- Resolved all testing report findings

## [1.2.0] - 2026-01-11

### Added

- **Input Validation**: Validation for command inputs with helpful error messages
- **Enhanced Linting**: Added errcheck and unconvert linters with proper exclusions
- **Pre-commit Hook**: Added `.githooks/pre-commit` running fmt, vet, lint, and short tests (`make setup-hooks`)
- Implemented missing features and resolved open issues from the initial release

### Documentation

- Clarified branching strategy and release process
- Updated AGENTS.md and CONTRIBUTING.md with hooks info

## [1.1.0] - 2026-01-10

### Added

#### Commands - Modules
- `canvas modules list` - List modules in a course
- `canvas modules get` - Get module details
- `canvas modules create` - Create new module
- `canvas modules update` - Update module
- `canvas modules delete` - Delete module
- `canvas modules relock` - Relock module progressions
- `canvas modules items` - List items in a module
- `canvas modules items get` - Get module item details
- `canvas modules items create` - Create module item
- `canvas modules items update` - Update module item
- `canvas modules items delete` - Delete module item
- `canvas modules items done` - Mark module item as done
- `canvas modules items not-done` - Mark module item as not done

#### Commands - Pages
- `canvas pages list` - List wiki pages in a course
- `canvas pages get` - Get page by URL or ID
- `canvas pages front` - Get front page
- `canvas pages create` - Create new page
- `canvas pages update` - Update existing page
- `canvas pages delete` - Delete page
- `canvas pages duplicate` - Duplicate page
- `canvas pages revisions` - List page revisions
- `canvas pages revert` - Revert to specific revision

#### Commands - Discussions
- `canvas discussions list` - List discussion topics
- `canvas discussions get` - Get discussion details
- `canvas discussions create` - Create new discussion
- `canvas discussions update` - Update discussion
- `canvas discussions delete` - Delete discussion
- `canvas discussions entries` - List discussion entries
- `canvas discussions post` - Post new entry
- `canvas discussions reply` - Reply to entry
- `canvas discussions subscribe` - Subscribe to topic
- `canvas discussions unsubscribe` - Unsubscribe from topic

#### Commands - Announcements
- `canvas announcements list` - List course announcements
- `canvas announcements get` - Get announcement details
- `canvas announcements create` - Create new announcement
- `canvas announcements update` - Update announcement
- `canvas announcements delete` - Delete announcement

#### Commands - Calendar
- `canvas calendar list` - List calendar events
- `canvas calendar get` - Get event details
- `canvas calendar create` - Create new event
- `canvas calendar update` - Update event
- `canvas calendar delete` - Delete event
- `canvas calendar reserve` - Reserve time slot

#### Commands - Planner
- `canvas planner items` - List planner items
- `canvas planner notes list` - List planner notes
- `canvas planner notes get` - Get note details
- `canvas planner notes create` - Create planner note
- `canvas planner notes update` - Update note
- `canvas planner notes delete` - Delete note
- `canvas planner complete` - Mark item as complete
- `canvas planner dismiss` - Dismiss item from planner
- `canvas planner overrides` - List planner overrides

### Testing
- Added comprehensive tests for all new API services
- Tests for Modules, Pages, Discussions, Announcements, Calendar, and Planner
- All tests passing with consistent patterns

## [1.0.0] - 2026-01-09

### Added

#### Core Functionality
- OAuth 2.0 authentication with PKCE support
- Local callback server mode for OAuth flow
- Out-of-band (OOB) OAuth flow fallback for SSH/remote environments
- Secure token storage using system keyring (macOS Keychain, Windows Credential Manager, Linux Secret Service)
- Encrypted file storage fallback with AES-256-GCM encryption
- User-derived encryption keys from machine ID + username
- Multi-instance configuration management
- Canvas version detection and compatibility handling

#### API Client Features
- Comprehensive Canvas LMS API client
- Adaptive rate limiting (5 req/sec → 2 req/sec → 1 req/sec based on quota)
- Automatic pagination handling for large result sets
- Exponential backoff retry logic with 3 max retries
- Data normalization for consistent API responses
- Custom error types with helpful suggestions and documentation links
- Request/response logging with --debug flag

#### Commands - Authentication
- `canvas auth login` - OAuth 2.0 authentication flow
- `canvas auth logout` - Logout and clear credentials
- `canvas auth status` - Check authentication status

#### Commands - Courses
- `canvas courses list` - List courses with filtering options
- `canvas courses get` - Get course details with includes
- `canvas courses users` - List users in a course

#### Commands - Assignments
- `canvas assignments list` - List assignments in a course
- `canvas assignments get` - Get assignment details
- `canvas assignments create` - Create new assignment with full parameter support
- `canvas assignments update` - Update assignment with pointer types for optional fields
- `canvas assignments bulk-update` - Bulk update multiple assignments

#### Commands - Users
- `canvas users me` - Get current authenticated user
- `canvas users list` - List users with filtering
- `canvas users get` - Get user details
- `canvas users create` - Create new user with pseudonym and communication channel
- `canvas users update` - Update user with avatar support

#### Commands - Enrollments
- `canvas enrollments list` - List enrollments in course/section
- `canvas enrollments create` - Create new enrollment

#### Commands - Submissions
- `canvas submissions list` - List submissions for assignment
- `canvas submissions get` - Get submission details
- `canvas submissions grade` - Grade individual submission
- `canvas submissions bulk-grade` - Bulk grade from CSV

#### Commands - Files
- `canvas files upload` - Upload files with progress tracking
- `canvas files download` - Download files with resumable support

#### Advanced Features
- **REPL Mode**: Interactive shell with command history, tab completion, and syntax highlighting
- **Smart Caching**: TTL-based caching (courses: 15min, users: 5min, assignments: 10min)
- **Batch Operations**: Concurrent processing with progress bars and error collection
- **Webhook Listener**: Real-time webhook event handling with signature verification
- **Diagnostics**: `canvas doctor` command for health checks and troubleshooting
- **Telemetry**: Opt-in anonymous usage tracking for feature prioritization

#### Output Formats
- Table format (ASCII tables with proper truncation)
- JSON format (structured output)
- YAML format (human-readable)
- CSV format (for data export)

#### Developer Features
- Comprehensive test suite with 90% coverage
- HTTP request/response recording for tests
- Mock Canvas API server for testing
- Synthetic test data (no PII in test fixtures)
- Race condition detection in tests
- CI/CD ready with stable exit codes

### Testing
- 90% test coverage for core functionality (89.9% weighted average)
- 8 out of 9 packages at 90%+ coverage
- All tests passing (100% pass rate)
- No race conditions detected
- Comprehensive parameter testing for all API operations
- Edge case coverage for error scenarios
- Mock HTTP server testing with httptest

### Security
- OAuth 2.0 with PKCE (Proof Key for Code Exchange)
- Secure credential storage with system keyring integration
- AES-256-GCM encryption for file-based token storage
- User-derived encryption keys (never stored)
- Webhook signature verification with HMAC-SHA256
- No hardcoded credentials
- No sensitive data in logs or cache

### Performance
- Adaptive rate limiting respects Canvas API quotas
- Smart caching reduces redundant API calls
- Concurrent batch operations (5 concurrent by default)
- Automatic pagination for large datasets
- Efficient memory usage (<100MB for 10,000 cached items)
- Progress indicators for operations >3 seconds

### Documentation
- Comprehensive README with quick start guide
- Architecture documentation in docs/development/architecture.md
- CONTRIBUTING.md with development guidelines
- Inline code documentation with examples

### Infrastructure
- Cross-platform support (macOS, Linux, Windows)
- Cobra CLI framework for command structure
- Viper for configuration management
- Standard Go project layout

---

[Unreleased]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.9.1...HEAD
[1.9.1]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.9.0...v1.9.1
[1.9.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.5.3...v1.6.0
[1.5.3]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/jjuanrivvera/canvas-cli/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/jjuanrivvera/canvas-cli/releases/tag/v1.0.0
````
