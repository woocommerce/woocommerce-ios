# frozen_string_literal: true

# Pure-Ruby helper for reading values out of `.xcconfig` files.
#
# Stateless and free of Fastlane dependencies so it can be exercised by unit
# tests without a Fastlane runtime.
module XcconfigHelper
  module_function

  # Returns the value assigned to `key` directly in the given xcconfig
  # contents, ignoring any `#include`d files and commented-out lines. Build
  # setting conditionals (`KEY[sdk=...]`) and inline `//` comments after the
  # value are not part of the returned value.
  #
  # @param contents [String] the xcconfig file contents
  # @param key [String] the build setting name, e.g. `DEVELOPMENT_TEAM`
  # @return [String, nil] the value, or nil when the key is not set in this file
  def value(contents, key)
    contents.each_line.filter_map { |line| line[/^\s*#{Regexp.escape(key)}\s*=\s*(\S+)/, 1] }.first
  end
end
