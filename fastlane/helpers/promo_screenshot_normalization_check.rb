# frozen_string_literal: true

require 'tmpdir'
require 'rmagick'
require_relative 'promo_screenshot_validation'

# Uses the locked image library to catch API and encoding regressions before composition.
module PromoScreenshotNormalizationCheck
  COLOR = '#720EEC'

  def self.create_fixture(path)
    image = Magick::Image.new(2, 3) { |options| options.background_color = 'transparent' }
    image.pixel_color(0, 0, COLOR)
    image.write("PNG32:#{path}")
    image.destroy!
    raise 'Fixture must have an alpha channel' unless File.binread(path, 26).getbyte(25) == 6
  end

  def self.rgb(pixel)
    [pixel.red, pixel.green, pixel.blue]
  end

  def self.check_pixels(path)
    image = Magick::Image.read(path).first
    raise 'Opaque source pixels changed' unless rgb(image.pixel_color(0, 0)) == rgb(Magick::Pixel.from_color(COLOR))
    raise 'Transparent pixels must become white' unless rgb(image.pixel_color(1, 1)) == [Magick::QuantumRange] * 3
  ensure
    image&.destroy!
  end

  def self.run
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'rgba.png')
      create_fixture(path)
      PromoScreenshotValidation.remove_alpha!(directory: directory, locales: ['.'])
      PromoScreenshotValidation.validate_image!(path, [2, 3])
      check_pixels(path)
    end
    puts 'Real RMagick normalization passed: RGBA to RGB8; dimensions and opaque pixels preserved.'
  end
end

PromoScreenshotNormalizationCheck.run
