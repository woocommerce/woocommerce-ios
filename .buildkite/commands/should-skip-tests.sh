#!/bin/bash

# Check if changes are limited to documentation, tooling and non-code files
pr_changed_files --all-match "*.md" "docs/**" "*.txt" "*.pot" "fastlane/**" ".github/**" ".buildkite/**"
