# frozen_string_literal: true

require 'fileutils'
require 'rmagick'

# Use the inner-open-landscape PNG from Apple's licensed iPhone Duo bezel package.
# Keep the reusable Apple artwork local; only composed app screenshots are release assets.
source = ARGV.fetch(0) { abort 'Pass the official iPhone Duo inner-open-landscape PNG path.' }
frame = Magick::Image.read(source).first
abort 'Expected the original 3093 × 2247 Apple bezel.' unless [frame.columns, frame.rows] == [3093, 2247]

assets = File.expand_path('../appstoreres/assets', __dir__)
output = File.join(assets, 'duo')
FileUtils.mkdir_p(output)

# Prescale with alpha-aware resampling; adaptive_resize leaves a fringe on this bezel.
frame.resize(2062, 1498).write(File.join(output, 'inner-landscape-frame.png'))

# The aperture is one connected transparent region around the image centre.
# Extend only the aperture under the inner edge; reaching the outer edge leaks screenshot pixels.
alpha = frame.channel(Magick::AlphaChannel)
opaque = alpha.threshold(Magick::QuantumRange - 1)
inside = opaque.color_floodfill(frame.columns / 2, frame.rows / 2, 'white')
coverage = inside.composite(opaque, 0, 0, Magick::DifferenceCompositeOp)
coverage = coverage.morphology(Magick::DilateMorphology, 1, Magick::KernelInfo.new('Disk:4'))
mask = coverage.crop(120, 120, 2853, 2007, true)
mask.alpha(Magick::CopyAlphaChannel)
mask.write(File.join(output, 'inner-landscape-mask.png'))

1.upto(2) do |index|
  background = Magick::Image.read(File.join(assets, "ipad-background-#{index}-landscape.png")).first
  background = background.resize_to_fill(2853, 2007)
  background.alpha(Magick::RemoveAlphaChannel)
  background.write("PNG24:#{File.join(output, "background-#{index}.png")}")
end

puts "Prepared Duo bezel, mask and backgrounds in #{output}"
