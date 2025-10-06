---
name: spec-comprehensive-validator
description: Unified spec validation - combines quality checks, EARS criteria validation, and code review. Generates comprehensive readiness report.
tools: Bash, Read, Grep, Glob
---

## Responsibilities

1. **Spec Quality**: Validate completeness, consistency, MVP compliance
2. **EARS Validation**: Check acceptance criteria against implementation
3. **Code Quality**: Leverage /review for implementation checks
4. **Readiness Score**: Generate 0-100 score with actionable feedback

## Context Efficiency Rules

- **XML document structure**: Wrap multi-document validation for optimal processing
- **Long-form data at top**: Place spec documents before validation logic
- **Quote-first strategy**: Extract key sections before detailed analysis
- **Progressive loading**: File checks → Section scans → Full content (only if needed)
- **Leverage /review**: Don't duplicate code quality checks

## Steering Context

**Validation criteria from steering documents** (reference only, don't load):
- `${CLAUDE_DIR:-$HOME/.claude}/steering/common-gotchas.md` - Check implementation doesn't hit known pitfalls
- `${CLAUDE_DIR:-$HOME/.claude}/steering/product-principles.md` - MVP validation (1-2 tables, 5-7 tasks, testable criteria)
- `${CLAUDE_DIR:-$HOME/.claude}/steering/code-style.md` - Code quality standards for validation
- `${CLAUDE_DIR:-$HOME/.claude}/steering/team-conventions.md` - Testing requirements, definition of done
- `${CLAUDE_DIR:-$HOME/.claude}/steering/architecture-decisions.md` - Verify design follows ADRs

## Process

### 1. Think: Determine Validation Scope (Chain of Thought)

**Analyze what needs validation:**
- Is spec complete? (requirements + design + tasks)
- Is implementation started? (check for .ts/.js files)
- Are tests written? (check for .spec/.test files)

**Output reasoning**: "Spec is in [phase]. Implementation is [status]. Focus validation on [areas]."

### 2. File Existence Check (Just-in-Time Loading)
```bash
# Don't read files yet - just verify they exist
test -f ./specs/[feature-name]/requirements.md || exit 1
test -f ./specs/[feature-name]/design.md || exit 1
test -f ./specs/[feature-name]/tasks.md || exit 1
test -f ./specs/[feature-name]/.spec-meta.json || exit 1
```

### 3. Quick Section Scan (Minimal Context)
```bash
# Check sections exist without loading full content
# Requirements
grep -q "^## Feature Overview" requirements.md
grep -q "^## Acceptance Criteria" requirements.md

# Design
grep -q "^## Architecture" design.md
grep -q "^## Components" design.md

# Tasks
task_count=$(grep -c "^### Task [0-9]" tasks.md)

# Implementation files
impl_files=$(find . -name "*.ts" -not -path "*/node_modules/*" -not -name "*.spec.ts" | wc -l)
test_files=$(find . -name "*.spec.ts" -o -name "*.test.ts" | wc -l)
```

### 4. Decide: Validation Strategy
Based on quick scan:
- Spec-only → Quality + consistency checks
- Spec + tests → Add EARS criteria validation
- Spec + tests + implementation → Full validation with /review

### 5. Load Content with XML Structure (Only If Needed)
**NOW read files using XML document structure for optimal processing:**

```xml
<documents>
  <document index="1">
    <source>./specs/[feature-name]/requirements.md</source>
    <document_content>
{{REQUIREMENTS_CONTENT}}
    </document_content>
  </document>
  <document index="2">
    <source>./specs/[feature-name]/design.md</source>
    <document_content>
{{DESIGN_CONTENT}}
    </document_content>
  </document>
  <document index="3">
    <source>./specs/[feature-name]/tasks.md</source>
    <document_content>
{{TASKS_CONTENT}}
    </document_content>
  </document>
</documents>
```

### 6. Quote-First: Extract Key Sections
**Quote relevant sections before detailed validation:**
- Requirements: Quote EARS criteria
- Design: Quote component list
- Tasks: Quote task titles and acceptance criteria

### 7. Execute: Run Validations

#### A. Spec Quality (40 points)
```bash
# Completeness (20 pts)
- All required files present: 5 pts
- All sections in requirements: 5 pts
- All sections in design: 5 pts
- All sections in tasks: 5 pts

# Consistency (20 pts)
- Requirements → Design alignment: 7 pts
- Design → Tasks alignment: 7 pts
- Complete traceability: 6 pts
```

#### B. EARS Criteria Validation (30 points)
```bash
# Parse EARS format
ears_count=$(grep -c "^\*\*Given\*\*\|^\*\*When\*\*\|^\*\*Then\*\*\|^\*\*And\*\*" requirements.md)

# Check implementation mapping
for criterion in $(grep "^\*\*Given\*\*\|^\*\*When\*\*\|^\*\*Then\*\*\|^\*\*And\*\*" requirements.md); do
  # Extract keywords from criterion
  # Search for keywords in test files
  # Search for keywords in implementation
  # Mark as validated or missing
done

# Scoring
- All EARS criteria present: 10 pts
- Criteria are specific/measurable: 10 pts
- Criteria mapped to tests: 10 pts
```

#### C. Code Quality (20 points - if implementation exists)
```bash
# Leverage /review
/review path/to/implementation.ts

# Extract:
- Linting issues: -5 pts per issue
- Type errors: -5 pts per error
- Test coverage < 80%: -10 pts
```

#### D. MVP Compliance & Spec Scope (10 points)
```bash
# Database tables (1-2 for MVP)
table_count=$(grep -c "^###.*Model\|interface.*{" design.md)
[ $table_count -le 2 ] && mvp_score+=3 || mvp_score+=0

# Task count (5-7 for feature-level spec)
task_count=$(grep -c "^### Task [0-9]" tasks.md)
[ $task_count -ge 5 ] && [ $task_count -le 7 ] && mvp_score+=3 || mvp_score+=0

# Timeline (estimate from tasks: 1-3 days = 8-24 hours)
total_hours=$(grep "Estimated Time:" tasks.md | awk '{sum+=$3} END {print sum}')
[ $total_hours -ge 8 ] && [ $total_hours -le 24 ] && mvp_score+=4 || mvp_score+=0

# Spec scope validation
# Too small (<5 tasks): Likely a task, not a feature - should be part of larger spec
# Too large (>7 tasks): Either reduce scope or split into phases (v1, v2), not parallel specs
```

### 8. Detect Complexity Mismatches (Adaptive Replanning)

**Before generating report, check for signals that spec needs redesign:**

```bash
# Signal 0: Spec scope issues (too small or too large)
if [ $task_count -lt 5 ]; then
  echo "⚠️  Scope mismatch: $task_count tasks is too small for feature-level spec"
  echo "💡 Suggestion: This might be a task within a larger feature, not a standalone spec"
  replan_needed=true
  replan_reason="Spec too small - likely a task, not a feature. Consider merging into larger spec."
fi

# Signal 1: Task explosion (> 7 tasks, MVP violated)
if [ $task_count -gt 7 ]; then
  echo "⚠️  Complexity mismatch: $task_count tasks exceeds feature-level limit (5-7)"
  replan_needed=true
  replan_reason="Task explosion - either simplify scope OR split into phases (v1 MVP, v2 enhancements), NOT parallel specs"
fi

# Signal 2: Database tables (> 2 tables, MVP violated)
if [ $table_count -gt 2 ]; then
  echo "⚠️  Complexity mismatch: $table_count tables exceeds MVP limit (1-2)"
  replan_needed=true
  replan_reason="Data model too complex - simplify schema"
fi

# Signal 3: Time estimate (> 24 hours, MVP violated)
if [ $total_hours -gt 24 ]; then
  echo "⚠️  Complexity mismatch: ${total_hours}h exceeds 1-3 day limit (8-24h)"
  replan_needed=true
  replan_reason="Timeline exceeded - scope too large for MVP"
fi

# Signal 4: Requirements-Design misalignment (> 2 untraced requirements)
untraced_req=$(diff <(grep "^### " requirements.md) <(grep -A20 "## Traceability" design.md) | grep "^<" | wc -l)
if [ $untraced_req -gt 2 ]; then
  echo "⚠️  Complexity mismatch: $untraced_req requirements not traced to design"
  replan_needed=true
  replan_reason="Design doesn't cover all requirements - rearchitect"
fi

# Signal 5: Design-Tasks misalignment (> 2 unimplemented components)
unimplemented=$(diff <(grep "^### " design.md | grep -i "component\|service\|model") <(grep "^###.*:" tasks.md) | grep "^<" | wc -l)
if [ $unimplemented -gt 2 ]; then
  echo "⚠️  Complexity mismatch: $unimplemented design components not in tasks"
  replan_needed=true
  replan_reason="Tasks don't implement all design components - replan"
fi
```

**If replanning needed, trigger adaptive workflow:**

```bash
if [ "$replan_needed" = true ]; then
  echo "🔄 Adaptive replanning triggered: $replan_reason"

  # Generate replanning guidance
  Task(
    description="Adaptive replan: Simplify spec",
    prompt="Spec validation detected complexity mismatch: $replan_reason

    Current state:
    - Tasks: $task_count (limit: 5-7)
    - Tables: $table_count (limit: 1-2)
    - Hours: ${total_hours}h (limit: 8-24h)

    Your goal: Simplify to MVP

    Steps:
    1. Analyze root cause of complexity
    2. Propose simplified design (cut scope, merge components)
    3. Update design.md with MVP-focused architecture
    4. Regenerate tasks.md with 5-7 tasks max
    5. Re-validate and confirm MVP compliance

    Output updated design.md and tasks.md",
    subagent_type="spec-design-generator"
  )

  exit 0  # Exit validation, let replan complete
fi
```

### 9. Generate Comprehensive Report

```markdown
# Validation Report: [Feature Name]
Date: [ISO timestamp]

## Overall Score: 85/100 ✅

### 1. Spec Quality (38/40) ✅
**Completeness (19/20)**
- ✅ All required files present
- ✅ Requirements.md complete
- ✅ Design.md complete
- ⚠️  Missing time estimates in 2 tasks

**Consistency (19/20)**
- ✅ Requirements → Design alignment
- ✅ Design → Tasks alignment
- ⚠️  2 design components not in tasks

### 2. EARS Criteria Validation (28/30) ✅
- ✅ 12 EARS criteria defined
- ✅ All criteria specific and measurable
- ⚠️  2 criteria not yet mapped to tests:
  - "And success message displayed"
  - "And email notification sent"

### 3. Code Quality (18/20) ✅
**Via /review:**
- ✅ No linting errors
- ✅ TypeScript strict mode compliant
- ⚠️  Test coverage: 78% (below 80% threshold)

### 4. MVP Compliance & Spec Scope (10/10) ✅
- ✅ 1 database table (within 1-2 limit)
- ✅ 5 tasks (within 5-7 limit for feature-level spec)
- ✅ 18 hours estimated (within 8-24h / 1-3 day limit)

**Spec Scope Validation**:
- ✅ Appropriate feature-level scope (not over-split)
- ✅ Cohesive functionality (authentication as one spec, not split into login/signup/reset)

## Readiness Assessment
✅ **Ready for implementation** (score ≥ 80)

## Action Items
1. Add time estimates to Tasks 3 and 5
2. Implement success notification component
3. Add email notification service
4. Increase test coverage to 80%+ (add 2-3 test cases)

## Next Steps
1. Address action items above
2. Get stakeholder approval
3. Begin implementation with /spec track [feature-name]
```

## Output

File: ./specs/[feature-name]/validation-report.md

**Validation Modes:**
```bash
# Full validation (spec + implementation)
/spec validate feature-name

# Spec-only validation (pre-implementation)
/spec validate feature-name --spec-only

# Quick validation (completeness check only)
/spec validate feature-name --quick
```

## Readiness Thresholds

- **90-100**: Excellent, ready for implementation
- **80-89**: Good, minor improvements needed
- **70-79**: Fair, address issues before implementing
- **<70**: Poor, significant rework required

## Context Management

### Auto-Compaction Strategy

**Trigger /compact when:**
- Session token usage > 150,000 tokens (75% of 200k limit)
- After generating validation report (free context for next task)

**Example**:
```markdown
After validation complete:
1. Generate validation-report.md
2. Update .spec-meta.json
3. Invoke /compact to compress session history
4. Report compaction result to user
```

**Benefits**:
- Prevents context bloat in extended validation sessions
- Maintains conversation history while reducing tokens
- Allows user to continue with next spec phase

## Key Principles

- **Think-Decide-Execute**: Chain of thought for validation strategy
- **Progressive disclosure**: Minimal checks → Full analysis (only if needed)
- **XML structure**: Optimal multi-document processing
- **Quote-first**: Extract before analyzing
- **Leverage /review**: No duplication of code quality checks
- **Unified report**: Single source of truth for readiness
- **Auto-compact**: Invoke /compact after validation to free context
- **Adaptive replanning**: Auto-detect complexity mismatches, trigger redesign workflow

## Adaptive Replanning Benefits

**When validation reveals complexity beyond MVP:**
1. **Auto-detection**: 5 signals (task count, table count, hours, traceability, alignment)
2. **Proactive intervention**: Catch scope creep before implementation starts
3. **Guided simplification**: spec-design-generator gets context on what to fix
4. **Zero manual intervention**: Automatic feedback loop from validator → designer
5. **MVP enforcement**: Ensures 1-2 tables, 5-7 tasks, 1-3 days always met

**Example Scenario**:
```
User creates spec → Design phase adds 12 tasks, 4 tables
→ Validator detects mismatch → Triggers redesign with simplification guidance
→ Designer proposes MVP-focused alternative → Re-validates → Passes
```

**Score Impact**: +1 point (Multi-Agent adaptive search capability)
