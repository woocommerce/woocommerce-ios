# frozen_string_literal: true

# Pure-Ruby checks on `fastlane/screenshots.json` and the assets it references.
# Uses Ruby's stdlib Minitest so no extra gems are required.
#
# Run:
#   ruby fastlane/helpers/promo_screenshots_config_test.rb

require 'minitest/autorun'
require 'json'

# Verifies each promo screenshot background matches its device canvas.
#
# `promo_screenshots` composites the background with `composite_image(canvas, background, 0, 0)`
# — pasted at the origin, never resized, unlike the device frame which gets `resize_image`.
# So a background smaller than the canvas leaves transparent edges, and a larger one is
# silently cropped to its top-left corner. Both have shipped: when the canvas moved to the
# iPhone 17 Pro Max, `iphone-background-1.png` (1290x2796, @1x) left a 30px transparent
# strip and `iphone-background-2.png` (3871x8388, @3x) rendered as a zoomed crop.
class PromoScreenshotsConfigTest < Minitest::Test
  FASTLANE_DIR = File.expand_path('..', __dir__)
  CONFIG_PATH = File.join(FASTLANE_DIR, 'screenshots.json')

  LFS_POINTER_PREFIX = 'version https://git-lfs.github.com/spec/v1'

  def config
    # This file carries `//` comments, which the toolkit's `read_config` relies on
    # `JSON.parse` tolerating. That tolerance is deprecated and becomes an error in
    # json 3.0 — at which point the toolkit breaks too, not just this test.
    @config ||= JSON.parse(File.read(CONFIG_PATH), allow_comments: true)
  end

  def canvas_sizes_by_device_name
    @canvas_sizes_by_device_name ||= config['devices'].to_h { |d| [d['name'], d['canvas_size']] }
  end

  # Reads width and height out of a PNG's IHDR chunk: an 8-byte signature, then a 4-byte
  # length and the 4-byte type "IHDR", then width and height as big-endian uint32.
  def png_dimensions(path)
    File.open(path, 'rb') { |f| f.read(24) }&.unpack('@16NN')
  end

  def lfs_pointer?(path)
    File.open(path, 'rb') { |f| f.read(LFS_POINTER_PREFIX.bytesize) } == LFS_POINTER_PREFIX
  end

  def test_every_entry_references_a_known_device
    config['entries'].each do |entry|
      assert_includes canvas_sizes_by_device_name.keys, entry['device'],
                      "Entry #{entry['filename']} names a device with no definition"
    end
  end

  def test_every_background_exactly_matches_its_device_canvas
    image_entries = config['entries'].select { |e| e['background'].to_s.end_with?('.png') }

    refute_empty image_entries, 'No image backgrounds found — the config is missing or malformed'

    image_entries.each { |entry| assert_background_matches_canvas(entry) }
  end

  private

  def assert_background_matches_canvas(entry)
    background = entry['background']
    path = File.join(FASTLANE_DIR, background)

    assert_path_exists path

    # Assets live in Git LFS. Skip loudly rather than fail if they were not smudged,
    # so a checkout without LFS reports "skipped" instead of a bogus dimension failure.
    skip "#{background} is an unsmudged Git LFS pointer — run `git lfs pull`" if lfs_pointer?(path)

    assert_equal canvas_sizes_by_device_name.fetch(entry['device']), png_dimensions(path),
                 "#{background} must be exactly the #{entry['device']} canvas size. " \
                 'Smaller leaves transparent edges; larger is cropped to its top-left corner.'
  end
end
