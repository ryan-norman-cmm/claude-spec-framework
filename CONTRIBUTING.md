# Contributing to Claude Spec Framework

Thank you for considering contributing to Claude Spec Framework! This document outlines the contribution process.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## How to Contribute

### Reporting Bugs

1. Check existing issues first
2. Create detailed bug report with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Claude Code version)
   - Relevant logs/screenshots

### Suggesting Features

1. Open a discussion first for major features
2. Explain the use case and benefits
3. Provide examples if possible

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push and create PR

### PR Guidelines

- **One feature per PR** - Keep PRs focused
- **Write tests** - Add tests for new features
- **Update docs** - Document new features/changes
- **Follow conventions** - Match existing code style

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/claude-spec-framework.git
cd claude-spec-framework

# Test installation locally
./scripts/install/install.sh --claude-dir /tmp/test-claude

# Make changes
# Test changes

# Run tests (if added)
./scripts/dev/test-install.sh
```

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use `${VAR}` for variable expansion
- Add comments for complex logic
- Keep functions focused and small

### Markdown

- Use headers hierarchically
- Include code examples
- Link to related docs
- Keep line length reasonable

### Agent Files

- Follow existing agent structure
- Include clear instructions
- Provide examples
- Document limitations

## Testing

### Manual Testing

```bash
# Test installation
./scripts/install/install.sh --auto

# Test slash commands
claude
/spec:init test-feature

# Test hooks
# Make file changes and verify hooks trigger
```

### Automated Testing (Future)

- Installation tests
- Hook tests
- Integration tests

## Documentation

### Update When

- Adding new features
- Changing behavior
- Fixing bugs (if docs were incorrect)

### Documentation Files

- `README.md` - Overview and quick start
- `docs/quick-start.md` - Detailed tutorial
- `docs/customization.md` - Configuration guide
- `docs/hooks-guide.md` - Hook system details
- `docs/examples/` - Working examples

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create git tag
4. Create GitHub release
5. Announce in discussions

## Questions?

- Open a discussion for general questions
- Open an issue for bugs/features
- Tag maintainers for urgent items

---

**Thank you for contributing!** 🎉
