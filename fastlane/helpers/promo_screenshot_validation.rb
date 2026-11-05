# frozen_string_literal: true

require 'json'

# Validate the whole replacement set before committing it for the overwrite uploader.
module PromoScreenshotValidation
  def self.validate_inputs!(directory:, locales:, config_path:)
    config = JSON.parse(File.read(config_path), allow_comments: true)
    locales.each do |locale|
      config.fetch('entries').each do |entry|
        screenshot = File.join(directory, locale, entry.fetch('screenshot'))
        raise "Missing source screenshot: #{screenshot}" unless File.file?(screenshot)

        validate_caption!(entry, locale, config_path)
      end
    end
  end

  def self.validate_caption!(entry, locale, config_path)
    caption = File.expand_path(entry.fetch('text').sub('{locale}', locale), File.dirname(config_path))
    raise "Missing or empty screenshot caption: #{caption}" unless File.file?(caption) && !File.read(caption).strip.empty?
  end

  def self.validate!(directory:, locales:, config_path:)
    config = JSON.parse(File.read(config_path), allow_comments: true)
    canvases = canvas_sizes(config)
    entries = config.fetch('entries')
    locales.each do |locale|
      folder = File.join(directory, locale)
      validate_filenames!(folder, locale, entries)
      entries.each do |entry|
        path = File.join(folder, entry.fetch('filename'))
        validate_image!(path, canvases.fetch(entry.fetch('device')))
      end
    end
  end

  def self.canvas_sizes(config)
    config.fetch('devices').to_h { |device| [device.fetch('name'), device.fetch('canvas_size')] }
  end

  def self.validate_filenames!(folder, locale, entries)
    expected = entries.map { |entry| entry.fetch('filename') }.sort
    actual = Dir.glob(File.join(folder, '*.png')).map { |path| File.basename(path) }.sort
    return if actual == expected

    raise "Incomplete promo screenshots for #{locale}: missing #{expected - actual}; unexpected #{actual - expected}"
  end

  def self.validate_image!(path, dimensions)
    header = File.binread(path, 33)
    validate_header!(header, path)
    raise "Wrong promo dimensions: #{path}" unless header[16, 8].unpack('NN') == dimensions
    raise "Promo screenshots must be 8-bit RGB without alpha: #{path}" unless header.getbyte(24) == 8 && header.getbyte(25) == 2

    validate_transparency!(path)
  end

  def self.validate_header!(header, path)
    valid = header.bytesize == 33 && header.start_with?("\x89PNG\r\n\x1a\n".b) && header[12, 4] == 'IHDR'
    raise "Invalid PNG: #{path}" unless valid
  end

  def self.validate_transparency!(path)
    File.open(path, 'rb') do |file|
      file.seek(33)
      loop do
        chunk = file.read(8)
        raise "Truncated PNG: #{path}" unless chunk&.bytesize == 8

        length, type = chunk.unpack('Na4')
        raise "Promo screenshots must not contain transparency: #{path}" if type == 'tRNS'

        break if type == 'IEND'

        file.seek(length + 4, IO::SEEK_CUR)
      end
    end
  end

  def self.remove_alpha!(directory:, locales:)
    require 'rmagick'

    locales.each do |locale|
      Dir.glob(File.join(directory, locale, '*.png')).each do |path|
        image = Magick::Image.read(path).first
        begin
          image.background_color = 'white'
          image.alpha(Magick::RemoveAlphaChannel)
          image.write("PNG24:#{path}") { |options| options.depth = 8 }
        ensure
          image.destroy!
        end
      end
    end
  end
end
