# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative 'promo_screenshot_validation'

# Exercises failure propagation in the checked-in lane, including its ensure cleanup.
class PromoCompositionFailureTest < Minitest::Test
  FASTLANE_DIR = File.expand_path('..', __dir__)
  FASTLANE_METADATA_FOLDER = File.join(FASTLANE_DIR, 'metadata')
  IOS_LOCALES = ['en-US'].freeze
  UI = Module.new do
    def self.message(*) = nil
  end

  def setup
    @directory = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def promo_screenshots(**)
    raise 'Compositor failed' if @fail_compositor
  end

  def compose(files_to_copy: [])
    original_screenshot_directory = @directory
    output_directory = @directory
    force = false
    source = File.read(File.join(FASTLANE_DIR, 'Fastfile'))
    lane_start = source.index('  lane :create_promo_screenshots ')
    start = source.index("    begin\n", lane_start)
    finish = source.index('    next unless commit || push', start)
    # Only repository code is evaluated; retain its location for require_relative resolution.
    # rubocop:disable-next Security/Eval, Style/DocumentDynamicEvalDefinition, Style/EvalWithLocation
    runner = eval("proc do\n#{source[start...finish]}\nend", binding, File.join(FASTLANE_DIR, 'Fastfile'), 1)
    PromoScreenshotValidation.stub(:validate_inputs!, nil) do
      PromoScreenshotValidation.stub(:remove_alpha!, nil) { runner.call }
    end
  end

  def test_compositor_failure_propagates_when_no_fallback_captions_were_copied
    @fail_compositor = true
    assert_equal 'Compositor failed', assert_raises(RuntimeError) { compose }.message
  end

  def test_incomplete_output_failure_propagates_when_no_fallback_captions_were_copied
    error = assert_raises(RuntimeError) { compose }
    assert_match(/Incomplete promo screenshots for en-US/, error.message)
  end

  def test_temporary_caption_cleanup_preserves_the_compositor_failure
    @fail_compositor = true
    caption = File.join(@directory, 'caption.txt')
    File.write(caption, 'Temporary fallback')
    assert_equal 'Compositor failed', assert_raises(RuntimeError) { compose(files_to_copy: [{ destination: caption }]) }.message
    refute_path_exists caption
  end
end
