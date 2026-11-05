# frozen_string_literal: true

require 'json'

# Validate the whole replacement set before committing it for the overwrite uploader.
module PromoScreenshotValidation
  def self.validate_inputs!(directory:, locales:, config_path:)
    config = JSON.parse(File.read(config_path), allow_comments: true)
    locales.each do |locale|
      config.fetch('entries').each do |entry|
        screenshot = File.join(directory, locale, entry.fetch('screenshot'))
        caption = File.expand_path(entry.fetch('text').sub('{locale}', locale), File.dirname(config_path))
        raise "Missing source screenshot: #{screenshot}" unless File.file?(screenshot)
        raise "Missing or empty screenshot caption: #{caption}" unless File.file?(caption) && !File.read(caption).strip.empty?
      end
    end
  end

  def self.validate!(directory:, locales:, config_path:)
    config = JSON.parse(File.read(config_path), allow_comments: true)
    canvases = config.fetch('devices').to_h { |device| [device.fetch('name'), device.fetch('canvas_size')] }
    entries = config.fetch('entries')
    expected = entries.map { |entry| entry.fetch('filename') }.sort
    locales.each do |locale|
      folder = File.join(directory, locale)
      actual = Dir.glob(File.join(folder, '*.png')).map { |path| File.basename(path) }.sort
      raise "Incomplete promo screenshots for #{locale}: missing #{expected - actual}; unexpected #{actual - expected}" unless actual == expected

      entries.each do |entry|
        path = File.join(folder, entry.fetch('filename'))
        header = File.binread(path, 33)
        valid = header.bytesize == 33 && header.start_with?("\x89PNG\r\n\x1a\n".b) && header[12, 4] == 'IHDR'
        raise "Invalid PNG: #{path}" unless valid
        raise "Wrong promo dimensions: #{path}" unless header[16, 8].unpack('NN') == canvases.fetch(entry.fetch('device'))
        raise "Promo screenshots must be 8-bit RGB without alpha: #{path}" unless header.getbyte(24) == 8 && header.getbyte(25) == 2
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
          image.depth = 8
          image.write("PNG24:#{path}")
        ensure
          image.destroy!
        end
      end
    end
  end
end
