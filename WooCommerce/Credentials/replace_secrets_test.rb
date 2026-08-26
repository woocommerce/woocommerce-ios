# frozen_string_literal: true

# Pure-Ruby unit tests for ReplaceSecrets. Uses Ruby's stdlib Minitest so
# no extra gems are required.
#
# Run:
#   ruby WooCommerce/Credentials/replace_secrets_test.rb

require 'json'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require_relative 'replace_secrets'

# Unit tests for ReplaceSecrets.
# rubocop:disable Style/FormatStringToken -- templates under test use %{key} placeholders
class ReplaceSecretsTest < Minitest::Test
  SCRIPT = File.expand_path('replace_secrets.rb', __dir__)

  def test_interpolate_replaces_placeholders
    template = "id = \"%{dotcom_app_id}\"\n"
    secrets = { dotcom_app_id: 'abc' }

    assert_equal "id = \"abc\"\n", ReplaceSecrets.interpolate(template, secrets)
  end

  def test_interpolate_stringifies_non_string_values
    template = 'count = %{retry_count}'
    secrets = { retry_count: 3 }

    assert_equal 'count = 3', ReplaceSecrets.interpolate(template, secrets)
  end

  def test_interpolate_ignores_unused_secret_keys
    template = '%{dotcom_app_id}'
    secrets = { dotcom_app_id: 'abc', extra: 'unused' }

    assert_equal 'abc', ReplaceSecrets.interpolate(template, secrets)
  end

  def test_interpolate_raises_when_a_key_is_missing
    error = assert_raises(ReplaceSecrets::MissingKeysError) do
      ReplaceSecrets.interpolate('%{dotcom_app_id}', {})
    end

    assert_equal [:dotcom_app_id], error.keys
    assert_match(/Missing secret key\(s\): dotcom_app_id/, error.message)
  end

  def test_interpolate_reports_every_missing_key_once
    error = assert_raises(ReplaceSecrets::MissingKeysError) do
      ReplaceSecrets.interpolate('%{foo} %{bar} %{foo}', { other: 'x' })
    end

    assert_equal %i[foo bar], error.keys
    assert_match(/Missing secret key\(s\): foo, bar/, error.message)
  end

  def test_process_injects_timestamp_and_replaces_keys
    with_files(template: "generated %{timestamp} id=%{dotcom_app_id}\n",
               secrets: { 'dotcom_app_id' => 'abc' }) do |input, secrets|
      result = ReplaceSecrets.process(input, secrets)

      refute_match(/%\{timestamp\}/, result)
      refute_match(/%\{dotcom_app_id\}/, result)
      assert_match(/^generated .+ id=abc$/, result)
    end
  end

  def test_cli_writes_interpolated_template_to_stdout
    with_files(template: "id = \"%{dotcom_app_id}\"\n",
               secrets: { 'dotcom_app_id' => 'abc' }) do |input, secrets|
      stdout, stderr, status = Open3.capture3('ruby', SCRIPT, '-i', input, '-s', secrets)

      assert status.success?, stderr
      assert_equal "id = \"abc\"\n", stdout
      assert_empty stderr
    end
  end

  def test_cli_exits_nonzero_on_missing_key_with_xcode_diagnostic
    with_files(template: '%{missing_key}',
               secrets: { 'dotcom_app_id' => 'abc' }) do |input, secrets|
      stdout, stderr, status = Open3.capture3('ruby', SCRIPT, '-i', input, '-s', secrets)

      refute status.success?
      assert_empty stdout
      assert_equal "#{input}:1: error: Missing secret key(s): missing_key\n", stderr
    end
  end

  def test_cli_exits_nonzero_when_secrets_file_is_missing
    with_files(template: '%{dotcom_app_id}', secrets: {}) do |input, secrets|
      File.delete(secrets)
      stdout, stderr, status = Open3.capture3('ruby', SCRIPT, '-i', input, '-s', secrets)

      refute status.success?
      assert_empty stdout
      assert_match(/:1: error: Missing or invalid --secrets argument/, stderr)
    end
  end

  def test_cli_exits_nonzero_when_secrets_file_is_invalid_json
    with_files(template: '%{dotcom_app_id}', secrets: {}) do |input, secrets|
      File.write(secrets, '{not json')
      stdout, stderr, status = Open3.capture3('ruby', SCRIPT, '-i', input, '-s', secrets)

      refute status.success?
      assert_empty stdout
      assert_match(/#{Regexp.escape(secrets)}:1: error: Secrets file is not valid JSON:/, stderr)
    end
  end

  def test_cli_exits_nonzero_when_required_flags_are_missing
    stdout, stderr, status = Open3.capture3('ruby', SCRIPT)

    refute status.success?
    assert_empty stdout
    assert_match(/:1: error: Missing or invalid --secrets argument/, stderr)
  end

  private

  def with_files(template:, secrets:)
    Dir.mktmpdir do |dir|
      input = File.join(dir, 'ApiCredentials.tpl')
      secrets_path = File.join(dir, 'woo_app_credentials.json')
      File.write(input, template)
      File.write(secrets_path, JSON.generate(secrets))
      yield input, secrets_path
    end
  end
end
# rubocop:enable Style/FormatStringToken
