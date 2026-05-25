# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/woo_ai_translation/manifest'

class ManifestTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, 'pl.json')
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def make_manifest
    WooAiTranslation::Manifest.new(locale: 'pl', path: @path)
  end

  def test_empty_manifest_needs_translation_for_any_key
    m = make_manifest
    assert m.needs_translation?(key: 'Cancel', source: 'Cancel')
    assert_equal 0, m.size
  end

  def test_recorded_entry_does_not_need_translation_when_source_unchanged
    m = make_manifest
    m.record!(key: 'Cancel', source: 'Cancel', model: 'claude-haiku-4-5', origin: 'ai')
    assert_equal 1, m.size
    refute m.needs_translation?(key: 'Cancel', source: 'Cancel')
  end

  def test_source_change_triggers_re_translation
    m = make_manifest
    m.record!(key: 'Cancel', source: 'Cancel', model: 'claude-haiku-4-5')
    assert m.needs_translation?(key: 'Cancel', source: 'Cancel the order')
  end

  def test_persists_and_reloads
    m1 = make_manifest
    m1.record!(key: 'Cancel', source: 'Cancel', model: 'claude-haiku-4-5', origin: 'bootstrap-2026-05-21')
    m1.save!
    assert File.exist?(@path)

    m2 = make_manifest
    assert_equal 1, m2.size
    entry = m2.entry('Cancel')
    assert_equal 'bootstrap-2026-05-21', entry['origin']
    assert_equal 'claude-haiku-4-5', entry['model']
    refute m2.needs_translation?(key: 'Cancel', source: 'Cancel')
  end

  def test_model_or_prompt_version_change_does_not_auto_invalidate
    m = make_manifest
    m.record!(key: 'Cancel', source: 'Cancel', model: 'claude-haiku-4-5')
    # Caller bumps the model on the fly; needs_translation? still returns
    # false because the SOURCE hasn't changed.
    refute m.needs_translation?(key: 'Cancel', source: 'Cancel')
  end

  def test_src_sha_is_deterministic_and_short
    sha = WooAiTranslation::Manifest.src_sha('Cancel')
    assert_equal 12, sha.length
    assert_equal sha, WooAiTranslation::Manifest.src_sha('Cancel')
    refute_equal sha, WooAiTranslation::Manifest.src_sha('cancel')
  end

  def test_record_preserves_explicit_prompt_version_and_origin
    m = make_manifest
    m.record!(key: 'X', source: 'X', model: 'claude-opus-4-7',
              origin: 'ai-opus-retry', prompt_version: '2026-06-01.test.1')
    e = m.entry('X')
    assert_equal 'claude-opus-4-7', e['model']
    assert_equal 'ai-opus-retry', e['origin']
    assert_equal '2026-06-01.test.1', e['pv']
  end

  def test_saved_file_is_pretty_and_sorted
    m = make_manifest
    m.record!(key: 'Cancel', source: 'Cancel', model: 'claude-haiku-4-5')
    m.record!(key: 'Apple', source: 'Apple', model: 'claude-haiku-4-5')
    m.save!
    raw = File.read(@path)
    apple_pos = raw.index('"Apple"')
    cancel_pos = raw.index('"Cancel"')
    assert apple_pos < cancel_pos, 'entries should be sorted alphabetically in saved JSON'
  end

  def test_default_path_lives_under_manifest_dir
    p = WooAiTranslation::Manifest.path_for(locale: 'pl')
    assert_match(%r{fastlane/ai_translation/manifest/pl\.json\z}, p)
  end

  def test_size_reflects_entry_count
    m = make_manifest
    assert_equal 0, m.size
    5.times { |i| m.record!(key: "k#{i}", source: "s#{i}") }
    assert_equal 5, m.size
  end
end
