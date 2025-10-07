#!/bin/bash
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Spec validation system
# Validates implementation against defined specifications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to validate requirements
validate_requirements() {
    local spec_dir=$1
    local requirements_file="$spec_dir/requirements.md"
    local validation_results=()
    local passed=0
    local failed=0

    print_color $CYAN "\n📋 Validating Requirements..."

    if [ ! -f "$requirements_file" ]; then
        print_color $RED "  ✗ Requirements file not found"
        return 1
    fi

    # Extract acceptance criteria from requirements
    local criteria_count=$(grep -c "^- \*\*Given\*\*" "$requirements_file" 2>/dev/null || echo 0)

    if [ "$criteria_count" -eq 0 ]; then
        print_color $YELLOW "  ⚠ No acceptance criteria found in EARS format"
        return 0
    fi

    print_color $BLUE "  Found $criteria_count acceptance criteria to validate"

    # Check each acceptance criterion
    while IFS= read -r line; do
        if [[ "$line" == "- **Given**"* ]]; then
            # Extract the criterion
            criterion=$(echo "$line" | sed 's/- \*\*Given\*\*/Given/')

            # For now, we'll mark criteria as "needs review"
            # In a real implementation, this would check against actual code/tests
            print_color $YELLOW "  ○ $criterion [needs review]"
        fi
    done < "$requirements_file"

    print_color $CYAN "  Requirements validation complete: Review needed for $criteria_count criteria"
}

# Function to validate design implementation
validate_design() {
    local spec_dir=$1
    local design_file="$spec_dir/design.md"
    local validation_results=()

    print_color $CYAN "\n🏗️  Validating Design Implementation..."

    if [ ! -f "$design_file" ]; then
        print_color $RED "  ✗ Design file not found"
        return 1
    fi

    # Check for component definitions
    local component_count=$(grep -c "^### Component" "$design_file" 2>/dev/null || echo 0)
    if [ "$component_count" -gt 0 ]; then
        print_color $GREEN "  ✓ Found $component_count component definitions"
    else
        print_color $YELLOW "  ⚠ No component definitions found"
    fi

    # Check for data models
    local model_count=$(grep -c "^### Model" "$design_file" 2>/dev/null || echo 0)
    if [ "$model_count" -gt 0 ]; then
        print_color $GREEN "  ✓ Found $model_count data model definitions"
    else
        print_color $YELLOW "  ⚠ No data model definitions found"
    fi

    # Check for API definitions
    local api_count=$(grep -c "^### Endpoint" "$design_file" 2>/dev/null || echo 0)
    if [ "$api_count" -gt 0 ]; then
        print_color $GREEN "  ✓ Found $api_count API endpoint definitions"
    else
        print_color $YELLOW "  ⚠ No API endpoint definitions found"
    fi

    print_color $CYAN "  Design validation complete"
}

# Function to validate task completion
validate_tasks() {
    local spec_dir=$1
    local tasks_file="$spec_dir/tasks.md"
    local total_tasks=0
    local completed_tasks=0
    local in_progress_tasks=0
    local pending_tasks=0

    print_color $CYAN "\n✅ Validating Task Completion..."

    if [ ! -f "$tasks_file" ]; then
        print_color $RED "  ✗ Tasks file not found"
        return 1
    fi

    # Count task statuses
    while IFS= read -r line; do
        if [[ "$line" == "- **Status:** "* ]]; then
            total_tasks=$((total_tasks + 1))
            if [[ "$line" == *"[x] Completed"* ]]; then
                completed_tasks=$((completed_tasks + 1))
            elif [[ "$line" == *"[x] In Progress"* ]]; then
                in_progress_tasks=$((in_progress_tasks + 1))
            else
                pending_tasks=$((pending_tasks + 1))
            fi
        fi
    done < "$tasks_file"

    if [ "$total_tasks" -eq 0 ]; then
        print_color $YELLOW "  ⚠ No tasks found in tasks.md"
        return 0
    fi

    # Calculate completion percentage
    local completion_percentage=0
    if [ "$total_tasks" -gt 0 ]; then
        completion_percentage=$((completed_tasks * 100 / total_tasks))
    fi

    # Display task status
    print_color $BLUE "  📊 Task Status:"
    print_color $GREEN "    ✓ Completed: $completed_tasks/$total_tasks"
    print_color $BLUE "    ○ In Progress: $in_progress_tasks/$total_tasks"
    print_color $YELLOW "    ○ Pending: $pending_tasks/$total_tasks"
    print_color $CYAN "    📈 Overall Completion: $completion_percentage%"

    # Update metadata with completion percentage
    local meta_file="$spec_dir/.spec-meta.json"
    if [ -f "$meta_file" ]; then
        temp_file=$(mktemp)
        jq ".completion_percentage = $completion_percentage | .last_updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$meta_file" > "$temp_file" && mv "$temp_file" "$meta_file"
    fi

    return 0
}

# Function to check test coverage
validate_tests() {
    local spec_dir=$1
    local tasks_file="$spec_dir/tasks.md"

    print_color $CYAN "\n🧪 Validating Test Coverage..."

    if [ ! -f "$tasks_file" ]; then
        print_color $RED "  ✗ Tasks file not found"
        return 1
    fi

    # Count required tests
    local unit_tests=$(grep -c "Unit test for" "$tasks_file" 2>/dev/null || echo 0)
    local integration_tests=$(grep -c "Integration test for" "$tasks_file" 2>/dev/null || echo 0)
    local e2e_tests=$(grep -c "End-to-end test for" "$tasks_file" 2>/dev/null || echo 0)

    print_color $BLUE "  📋 Required Tests:"
    if [ "$unit_tests" -gt 0 ]; then
        print_color $BLUE "    • Unit tests: $unit_tests"
    fi
    if [ "$integration_tests" -gt 0 ]; then
        print_color $BLUE "    • Integration tests: $integration_tests"
    fi
    if [ "$e2e_tests" -gt 0 ]; then
        print_color $BLUE "    • E2E tests: $e2e_tests"
    fi

    if [ "$unit_tests" -eq 0 ] && [ "$integration_tests" -eq 0 ] && [ "$e2e_tests" -eq 0 ]; then
        print_color $YELLOW "  ⚠ No test requirements found in tasks"
    fi

    return 0
}

# Function to generate validation report
generate_report() {
    local spec_dir=$1
    local report_file="$spec_dir/validation-report.md"
    local spec_name=$(basename "$spec_dir")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$report_file" << EOF
# Validation Report for $spec_name

**Generated:** $timestamp

## Summary
This report provides validation results for the spec-driven implementation of **$spec_name**.

## Validation Results

### ✅ Requirements Validation
$(validate_requirements "$spec_dir" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^//')

### 🏗️ Design Validation
$(validate_design "$spec_dir" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^//')

### 📋 Task Completion
$(validate_tasks "$spec_dir" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^//')

### 🧪 Test Coverage
$(validate_tests "$spec_dir" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^//')

## Recommendations
- Review all acceptance criteria marked as "needs review"
- Complete any pending tasks before deployment
- Ensure all required tests are implemented
- Update specifications if implementation diverged from original design

## Files Tracked
EOF

    # Add modification log if it exists
    if [ -f "$spec_dir/.modifications.log" ]; then
        echo -e "\n### Modified Files" >> "$report_file"
        echo '```' >> "$report_file"
        tail -10 "$spec_dir/.modifications.log" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    # Add validation log if it exists
    if [ -f "$spec_dir/.validations.log" ]; then
        echo -e "\n### Validation Commands Run" >> "$report_file"
        echo '```' >> "$report_file"
        tail -10 "$spec_dir/.validations.log" >> "$report_file"
        echo '```' >> "$report_file"
    fi

    print_color $GREEN "\n📄 Validation report generated: $report_file"
}

# Main function
main() {
    local feature_name=$1

    if [ -z "$feature_name" ]; then
        print_color $RED "Error: Feature name is required"
        echo "Usage: $0 <feature-name>"
        exit 1
    fi

    local spec_dir="${CLAUDE_DIR}/specs/active/$feature_name"

    if [ ! -d "$spec_dir" ]; then
        print_color $RED "Error: Spec for '$feature_name' not found"
        exit 1
    fi

    print_color $CYAN "═══════════════════════════════════════════════════════"
    print_color $CYAN "     Spec Validation for: $feature_name"
    print_color $CYAN "═══════════════════════════════════════════════════════"

    # Run all validations
    validate_requirements "$spec_dir"
    validate_design "$spec_dir"
    validate_tasks "$spec_dir"
    validate_tests "$spec_dir"

    # Generate report
    generate_report "$spec_dir"

    print_color $CYAN "\n═══════════════════════════════════════════════════════"
    print_color $GREEN "     Validation Complete!"
    print_color $CYAN "═══════════════════════════════════════════════════════"
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi