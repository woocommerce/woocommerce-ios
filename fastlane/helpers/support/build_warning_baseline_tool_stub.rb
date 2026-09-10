# frozen_string_literal: true

require 'fileutils'
require 'json'

# Local stand-ins for the baseline script's build, cache, and artifact tools.
module BuildWarningBaselineToolStub
  module_function

  def run(command, arguments)
    record(command, arguments)
    case command
    when 'baseline-setup' then nil
    when 'bundle' then build(arguments)
    when 'restore_cache' then restore(arguments.fetch(0))
    when 'save_cache' then save(*arguments)
    when 'upload_artifact', 'buildkite-agent' then upload(command, arguments)
    else abort "Unexpected external command: #{command}"
    end
  end

  def record(command, arguments)
    call = { command: command, arguments: arguments, directory: Dir.pwd }
    File.open(ENV.fetch('BASELINE_TEST_CALLS'), 'a') { |file| file.puts(JSON.generate(call)) }
  end

  def build(arguments)
    abort 'Unexpected build command' unless arguments == %w[exec fastlane build_for_testing]

    FileUtils.mkdir_p('fastlane/logs')
    File.write('fastlane/logs/build.log', "#{Dir.pwd}/WooCommerce/Fixture.swift:12:3: warning: baseline fixture\n")
  end

  def restore(key)
    source = File.join(ENV.fetch('BASELINE_TEST_SHARED_CACHE'), "#{key}.json")
    return unless File.file?(source)

    FileUtils.mkdir_p('build-warning-baseline-cache')
    FileUtils.cp(source, 'build-warning-baseline-cache/base-build-warnings.json')
  end

  def save(directory, key)
    source = File.join(directory, 'base-build-warnings.json')
    destination = File.join(ENV.fetch('BASELINE_TEST_SHARED_CACHE'), "#{key}.json")
    FileUtils.cp(source, destination) unless File.file?(destination)
  end

  def upload(command, arguments)
    expected = command == 'upload_artifact' ? ['base-build-warnings.json'] : %w[artifact upload base-build-warnings.json]
    abort 'Unexpected artifact arguments' unless arguments == expected

    destination = File.join(ENV.fetch('BASELINE_TEST_UPLOADS'), "#{command}.json")
    FileUtils.cp(arguments.last, destination)
  end
end

BuildWarningBaselineToolStub.run(File.basename($PROGRAM_NAME), ARGV)
