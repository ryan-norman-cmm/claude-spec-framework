# Claude Spec Framework

> **Spec-driven development framework for Claude Code with automated TDD tracking**

Transform your development workflow with a structured approach to building features: from requirements → design → implementation, with automated test tracking and quality gates.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/ryan-norman-cmm/claude-spec-framework)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ✨ Features

### Core Workflow
- 🎯 **EARS Requirements** - Generate precise requirements using EARS format (Event-Action-Response-State)
- 🏗️ **Technical Design** - Automatic design generation from requirements with architecture analysis
- ✅ **TDD Task Breakdown** - Sequential tasks with built-in Red-Green-Refactor checkboxes
- ♻️ **Automated TDD Tracking** - Real-time test status updates via hooks (zero tokens!)
- 🔍 **Spec Validation** - Comprehensive quality checks for requirements, design, and tasks
- 📊 **Requirements Mapping** - Validate all EARS criteria are tested

### Enhanced Capabilities
- 📥 **Requirements Import** - Import from JIRA, GitHub Issues, and external docs
- 🧪 **E2E Test Generation** - Generate Cucumber/Playwright tests with Docker environments
- ✔️ **Task Completion Evaluation** - Comprehensive validation of requirements, tests, and docs
- 🚦 **Phase Gates** - Prevent mistakes by enforcing workflow order
- 📈 **Progress Tracking** - Visual status indicators and metadata sync

## 🚀 Quick Install

### One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ryan-norman-cmm/claude-spec-framework/main/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/ryan-norman-cmm/claude-spec-framework.git
cd claude-spec-framework
./install.sh
```

### Installation Options

```bash
./install.sh                # Interactive - add new files only
./install.sh --auto         # Non-interactive - add new files only
./install.sh --force        # Overwrite all files (creates backup)
./install.sh --skip-hooks   # Install without hooks (manual config)
```

**Default Behavior**: Only new files are added. Existing files are preserved.
**Force Mode** (`--force`): Overwrites ALL files and creates a timestamped backup in `~/.claude/.backups/`

### Upgrading

To upgrade your installation with the latest changes:

```bash
cd claude-spec-framework
git pull
./install.sh --auto         # Only adds new files (recommended)
# OR
./install.sh --force        # Overwrites everything (use if you haven't customized)
```

**Installation Status Indicators**:
- `+` = New file added
- `↻` = Existing file updated (force mode only)
- `-` = Existing file skipped (default mode)

## 📚 Quick Start

### 1. Initialize a Spec

```bash
claude  # Start Claude Code
/spec:init user-authentication
```

This generates:
- `specs/user-authentication/requirements.md` - EARS format requirements
- `specs/user-authentication/design.md` - Technical design
- `specs/user-authentication/tasks.md` - TDD task breakdown
- `specs/user-authentication/.spec-meta.json` - Metadata

### 2. Implement with TDD

```bash
# Tasks are auto-tracked via hooks!

# Step 1: Write failing test
# → Hook marks: [x] Tests written and failing (Red)

# Step 2: Implement feature
# → Hook marks: [x] Implementation complete

# Step 3: Tests pass
# → Hook marks: [x] Tests passing (Green)
# → Status changes to: [x] Completed
```

### 3. Validate Quality

```bash
/spec:validate user-authentication
```

Checks:
- Requirements quality (EARS compliance)
- Design completeness
- Task breakdown structure
- Test coverage mapping

### 4. Sync with Code

```bash
/spec:sync user-authentication
```

Updates tasks based on actual code changes (Code → Spec sync).

## 🎯 Workflow Example

```bash
# 1. Create spec
/spec:init password-reset

# 2. Review and refine requirements
# Edit: specs/password-reset/requirements.md

# 3. Regenerate design + tasks from updated requirements
/spec:refine password-reset

# 4. Implement (hooks auto-track progress)
# Write tests → Implement → Tests pass → Task completed ✅

# 5. Validate before completion
/spec:validate password-reset

# 6. Complete spec (validation ≥90, tests pass, create commit)
/spec:complete password-reset
# ✅ Creates completion commit with summary

# 7. Create PR
gh pr create
```

## 🛠️ Commands Reference

### Full Workflow
- `/spec:init <feature>` - Initialize spec and generate all phases
- `/spec:complete <feature>` - Complete spec with validation, tests, and commit

### Individual Phases
- `/spec:requirements <feature>` - Generate requirements.md only
- `/spec:design <feature>` - Generate design.md only
- `/spec:tasks <feature>` - Generate tasks.md only

### Quality & Sync
- `/spec:validate <feature>` - Comprehensive spec validation
- `/spec:sync <feature>` - Update tasks from code (Code → Spec)
- `/spec:refine <feature>` - Regenerate design + tasks (Spec → Code)

### Status
- `/spec:status [feature]` - Show spec status and progress
- `/spec:list` - List all specs with details

## 🪝 Hook System

Automated workflow enhancements through intelligent hooks:

### Pre-Tool-Use Hooks
- **Phase Gate** - Prevents out-of-order workflow (e.g., can't implement before design)

### Post-Tool-Use Hooks
- **TDD Tracking** - Auto-updates task checkboxes when tests written/passing
- **Metadata Sync** - Keeps `.spec-meta.json` current with file changes
- **Requirements Validation** - Ensures EARS criteria are tested
- **NX Quality** (optional) - NX monorepo-specific quality checks

### User-Prompt-Submit Hooks
- **Workflow Guidance** - Contextual suggestions based on current spec phase

**Note**: All hooks are **zero-token** - pure bash for instant execution!

## 📖 Documentation

- [Quick Start Guide](docs/quick-start.md) - Step-by-step tutorial
- [Spec Best Practices](docs/spec-best-practices.md) - Writing effective specs
- [Hook System Guide](docs/hooks-guide.md) - Understanding automation
- [Customization Guide](docs/customization.md) - Tailor to your workflow
- [Examples](docs/examples/) - Real-world spec examples

## 🔧 Requirements

- **Claude Code CLI** (latest version)
- **jq** - JSON processor (auto-installed by installer)
- **Git** - For metadata tracking
- **Test framework** (optional) - Jest, Vitest, or Mocha for TDD tracking

## 🎨 Customization

Create `~/.claude/spec-framework.config.json`:

```json
{
  "hooks": {
    "enabled": ["tdd-tracking", "metadata-sync"],
    "disabled": ["nx-quality"]
  },
  "specs_directory": "./specs",
  "tdd_strict_mode": false,
  "nx_integration": true
}
```

See [Customization Guide](docs/customization.md) for details.

## 🏆 Why This Framework?

### Before
- ❌ Ad-hoc feature planning
- ❌ Manual task tracking
- ❌ Forgotten requirements
- ❌ Inconsistent TDD practices
- ❌ No requirements-to-test mapping

### After
- ✅ Structured EARS requirements
- ✅ Automated TDD cycle tracking
- ✅ Real-time progress updates
- ✅ Requirements validation
- ✅ Quality gates and validation

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for [Claude Code](https://claude.com/claude-code) by Anthropic
- Inspired by spec-driven development best practices
- TDD automation inspired by the Kiro workflow

## 🔗 Links

- [Documentation](docs/)
- [Issues](https://github.com/ryan-norman-cmm/claude-spec-framework/issues)
- [Discussions](https://github.com/ryan-norman-cmm/claude-spec-framework/discussions)
- [Claude Code Docs](https://docs.claude.com/claude-code)

---

**Made with ❤️ for the Claude Code community**
