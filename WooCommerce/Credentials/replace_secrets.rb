#!/usr/bin/env ruby
# frozen_string_literal: true

##
## This Script loads a collection of (JSON Encoded) secrets, and performs replacement operations
## over a given Template.
##
##  Note that in order for the Replacement OP's to work, your placeholders should look like this:
##
##	%{WOO_CREDENTIALS}
##
require 'json'
require 'optparse'

# Interpolates `%{key}` placeholders in a template using a JSON secrets file.
class ReplaceSecrets
  class Error < StandardError; end

  # Raised when the template references a key absent from the secrets JSON.
  class MissingKeysError < Error
    attr_reader :keys

    def initialize(keys)
      @keys = keys
      super("Missing secret key(s): #{keys.join(', ')}")
    end
  end

  PLACEHOLDER = /%\{(\w+)\}/

  def self.load_secrets(secrets_path)
    raw_secrets = File.read(secrets_path)
    output = JSON.parse(raw_secrets, symbolize_names: true)
    output[:timestamp] = Time.now.strftime('%b %d, %Y at %H:%M:%S')
    output
  end

  def self.interpolate(template, secrets)
    missing = []
    result = template.gsub(PLACEHOLDER) do |match|
      key = Regexp.last_match(1).to_sym
      if secrets.key?(key)
        secrets[key].to_s
      else
        missing << key
        match
      end
    end
    raise MissingKeysError, missing.uniq if missing.any?

    result
  end

  def self.process(template_path, secrets_path)
    interpolate(File.read(template_path), load_secrets(secrets_path))
  end

  # Clang diagnostic (`file:line:column: error:`) so Xcode's issue navigator shows the message.
  def self.xcode_error(path, message)
    "#{path}:1:1: error: #{message}"
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}

  optparse = OptionParser.new do |opts|
    opts.on('-s', '--secrets file', 'Secrets filename (must be in JSON format!)') do |secrets|
      options[:secrets] = secrets
    end

    opts.on('-i', '--input file', 'Input filename') do |input|
      options[:input] = input
    end
  end

  optparse.parse!

  %i[secrets input].each do |parameter|
    filename = options[parameter]
    next if filename && File.exist?(filename)

    warn ReplaceSecrets.xcode_error($PROGRAM_NAME, "Missing or invalid --#{parameter} argument")
    warn optparse
    exit 1
  end

  begin
    print ReplaceSecrets.process(options[:input], options[:secrets])
  rescue ReplaceSecrets::MissingKeysError => e
    warn ReplaceSecrets.xcode_error(options[:input], e.message)
    exit 1
  rescue JSON::ParserError => e
    warn ReplaceSecrets.xcode_error(options[:secrets], "Secrets file is not valid JSON: #{e.message}")
    exit 1
  end
end
