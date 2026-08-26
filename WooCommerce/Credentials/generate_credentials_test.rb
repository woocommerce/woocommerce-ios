# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Integration tests for the credentials build phase.
class GenerateCredentialsTest < Minitest::Test
  SCRIPT = File.expand_path('../../Scripts/build-phases/generate-credentials.sh', __dir__)
  SOURCE_ROOT = File.expand_path('..', __dir__)
  TEMPLATE = File.join(__dir__, 'ApiCredentials.tpl')

  def test_generation_writes_identical_content_to_every_output
    with_generation_files(secrets: complete_secrets) do |environment, outputs|
      stdout, stderr, status = Open3.capture3(environment, SCRIPT)

      assert status.success?, "#{stdout}\n#{stderr}"
      assert_equal File.read(outputs.first), File.read(outputs.last)
      refute_match(/%\{\w+\}/, File.read(outputs.first))
    end
  end

  def test_generation_failure_preserves_existing_outputs
    secrets = complete_secrets
    secrets.delete('dotcom_secret')

    with_generation_files(secrets: secrets, contents: %w[first second]) do |environment, outputs|
      stdout, stderr, status = Open3.capture3(environment, SCRIPT)

      refute status.success?
      diagnostic = "#{TEMPLATE}:1: error: Missing secret key(s): dotcom_secret"
      assert_match(/#{Regexp.escape(diagnostic)}/, stderr)
      assert_match(/#{Regexp.escape(diagnostic)}/, stdout)
      generated_contents = outputs.map { |output| File.read(output) }
      assert_equal %w[first second], generated_contents
    end
  end

  private

  def complete_secrets
    File.read(TEMPLATE).scan(/%\{(\w+)\}/).flatten.uniq.to_h { |key| [key, "value-for-#{key}"] }
  end

  def with_generation_files(secrets:, contents: ['', ''])
    Dir.mktmpdir do |directory|
      write_secrets(directory, secrets)
      outputs = write_outputs(directory, contents)
      yield generation_environment(directory, outputs), outputs
    end
  end

  def write_secrets(directory, secrets)
    secrets_directory = File.join(directory, '.configure/woocommerce-ios/secrets')
    FileUtils.mkdir_p(secrets_directory)
    File.write(File.join(secrets_directory, 'woo_app_credentials.json'), JSON.generate(secrets))
  end

  def write_outputs(directory, contents)
    contents.each_with_index.map do |content, index|
      File.join(directory, "output-#{index}.swift").tap { |path| File.write(path, content) }
    end
  end

  def generation_environment(directory, outputs)
    environment = {
      'ACTION' => 'build',
      'HOME' => directory,
      'PATH' => "#{File.dirname(RbConfig.ruby)}:/usr/bin:/bin",
      'SCRIPT_OUTPUT_FILE_COUNT' => outputs.count.to_s,
      'SOURCE_ROOT' => SOURCE_ROOT
    }
    outputs.each_with_index { |output, index| environment["SCRIPT_OUTPUT_FILE_#{index}"] = output }
    environment
  end
end
