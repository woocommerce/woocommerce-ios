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

class ReplaceSecrets
  class Error < StandardError; end

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

    if filename.nil? || File.exist?(filename) == false
      warn "error: Missing or invalid --#{parameter} argument"
      warn optparse
      exit 1
    end
  end

  begin
    print ReplaceSecrets.process(options[:input], options[:secrets])
  rescue ReplaceSecrets::MissingKeysError => e
    warn "error: #{e.message} (required by #{options[:input]})"
    exit 1
  rescue JSON::ParserError => e
    warn "error: Secrets file is not valid JSON: #{e.message}"
    exit 1
  end
end
