# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'zlib'
require_relative 'promo_screenshot_validation'

# Rejects partial replacement sets and PNG formats that App Store Connect cannot accept.
class PromoScreenshotValidationTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir
    @config = File.join(@directory, 'config.json')
    File.write(@config, JSON.generate(devices: [{ name: 'Duo', canvas_size: [2, 3] }],
                                      entries: [{ device: 'Duo', filename: 'duo.png', screenshot: 'duo.png',
                                                  text: 'metadata/{locale}/caption.txt' }]))
    %w[en-US de-DE].each do |locale|
      write_png(locale)
      FileUtils.mkdir_p(File.join(@directory, 'metadata', locale))
      File.write(File.join(@directory, 'metadata', locale, 'caption.txt'), 'Localized caption')
    end
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def validate
    PromoScreenshotValidation.validate!(directory: @directory, locales: %w[en-US de-DE], config_path: @config)
  end

  def write_png(locale, width: 2, alpha: false, transparency: false)
    FileUtils.mkdir_p(File.join(@directory, locale))
    File.binwrite(File.join(@directory, locale, 'duo.png'), png_bytes(width, alpha, transparency))
  end

  def png_chunk(type, data)
    [data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
  end

  def png_pixels(width, alpha)
    ("\0".b + ("\xff".b * width * (alpha ? 4 : 3))) * 3
  end

  def png_bytes(width, alpha, transparency)
    header = [width, 3, 8, alpha ? 6 : 2, 0, 0, 0].pack('NNCCCCC')
    bytes = "\x89PNG\r\n\x1a\n".b + png_chunk('IHDR', header)
    bytes += png_chunk('tRNS', [0, 0, 0].pack('n3')) if transparency
    bytes + png_chunk('IDAT', Zlib.deflate(png_pixels(width, alpha))) + png_chunk('IEND', '')
  end

  def test_complete_rgb_set_passes
    validate
  end

  def test_missing_locale_fails
    FileUtils.remove_entry(File.join(@directory, 'de-DE'))
    assert_match(/Incomplete.*de-DE/, assert_raises(RuntimeError) { validate }.message)
  end

  def test_missing_scene_fails
    File.delete(File.join(@directory, 'de-DE', 'duo.png'))
    assert_match(/missing.*duo.png/, assert_raises(RuntimeError) { validate }.message)
  end

  def test_unexpected_image_fails
    FileUtils.cp(File.join(@directory, 'en-US', 'duo.png'), File.join(@directory, 'en-US', 'obsolete.png'))
    assert_match(/unexpected.*obsolete.png/, assert_raises(RuntimeError) { validate }.message)
  end

  def test_wrong_canvas_fails
    write_png('de-DE', width: 1)
    assert_match(/Wrong promo dimensions/, assert_raises(RuntimeError) { validate }.message)
  end

  def test_alpha_channel_fails_even_when_every_pixel_is_opaque
    write_png('de-DE', alpha: true)
    assert_match(/without alpha/, assert_raises(RuntimeError) { validate }.message)
  end

  def test_rgb_transparency_chunk_fails
    write_png('de-DE', transparency: true)
    assert_match(/must not contain transparency/, assert_raises(RuntimeError) { validate }.message)
  end

  def validate_inputs
    PromoScreenshotValidation.validate_inputs!(directory: @directory, locales: %w[en-US de-DE], config_path: @config)
  end

  def test_localized_inputs_pass
    validate_inputs
  end

  def test_missing_raw_scene_fails_before_render
    File.delete(File.join(@directory, 'de-DE', 'duo.png'))
    assert_match(/Missing source screenshot/, assert_raises(RuntimeError) { validate_inputs }.message)
  end

  def test_missing_localized_caption_fails_before_render
    File.delete(File.join(@directory, 'metadata', 'de-DE', 'caption.txt'))
    assert_match(/Missing or empty screenshot caption/, assert_raises(RuntimeError) { validate_inputs }.message)
  end

  def test_whitespace_caption_fails_before_render
    File.write(File.join(@directory, 'metadata', 'de-DE', 'caption.txt'), " \n")
    assert_match(/Missing or empty screenshot caption/, assert_raises(RuntimeError) { validate_inputs }.message)
  end
end
