#!/bin/bash

# Script to extract all issues and comments from solana-foundation/explorer repo
# and save them to a markdown file

REPO="solana-foundation/explorer"
OUTPUT_FILE="solana_explorer_issues.md"

echo "Extracting issues and comments from $REPO..."
echo "This may take a while due to the number of issues..."

# Create the markdown file header
cat > "$OUTPUT_FILE" << EOF
# Issues and Comments from Solana Explorer Repository

Repository: [https://github.com/$REPO](https://github.com/$REPO)
Generated on: $(date)

---

EOF

# Function to extract comments for a specific issue
extract_comments() {
    local issue_number=$1
    echo "  Fetching comments for issue #$issue_number..."
    
    # Get comments for this issue
    gh api "repos/$REPO/issues/$issue_number/comments" --paginate | jq -r '.[] | "### Comment by @" + .user.login + " on " + .created_at + "\n\n" + .body + "\n\n---\n"' >> "$OUTPUT_FILE"
}

# Get all issues (both open and closed) with pagination
echo "Fetching all issues (open and closed)..."
gh api "repos/$REPO/issues?state=all" --paginate -q '.[] | select(.pull_request == null) | {number: .number, title: .title, state: .state, user: .user.login, created_at: .created_at, updated_at: .updated_at, body: .body, comments: .comments, html_url: .html_url}' | jq -s '.' > issues_temp.json

# Process each issue
jq -c '.[]' issues_temp.json | while read -r issue; do
    number=$(echo "$issue" | jq -r '.number')
    title=$(echo "$issue" | jq -r '.title')
    state=$(echo "$issue" | jq -r '.state')
    user=$(echo "$issue" | jq -r '.user')
    created_at=$(echo "$issue" | jq -r '.created_at')
    updated_at=$(echo "$issue" | jq -r '.updated_at')
    body=$(echo "$issue" | jq -r '.body // "No description provided."')
    comments_count=$(echo "$issue" | jq -r '.comments')
    html_url=$(echo "$issue" | jq -r '.html_url')
    
    echo "Processing issue #$number: $title"
    
    # Add issue to markdown file
    cat >> "$OUTPUT_FILE" << EOF
## Issue #$number: $title

**Status:** $state  
**Author:** @$user  
**Created:** $created_at  
**Updated:** $updated_at  
**URL:** [$html_url]($html_url)  
**Comments:** $comments_count

### Description

$body

EOF

    # If there are comments, fetch them
    if [ "$comments_count" -gt 0 ]; then
        echo "### Comments" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        extract_comments "$number"
    fi
    
    echo "" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

# Clean up temporary file
rm -f issues_temp.json

echo "✅ Issues and comments have been extracted to $OUTPUT_FILE"
echo "📊 Summary:"
issue_count=$(grep -c "^## Issue #" "$OUTPUT_FILE")
echo "   - Total issues: $issue_count"
comment_count=$(grep -c "^### Comment by" "$OUTPUT_FILE")
echo "   - Total comments: $comment_count"
echo "   - File size: $(du -h "$OUTPUT_FILE" | cut -f1)" 