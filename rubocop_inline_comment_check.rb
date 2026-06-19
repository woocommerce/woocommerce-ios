# frozen_string_literal: true

# Deliberate RuboCop violation used to check whether the dedicated CI RuboCop
# step posts inline PR comments. Remove before merge.
message = "double-quoted string triggers Style/StringLiterals"
puts message
