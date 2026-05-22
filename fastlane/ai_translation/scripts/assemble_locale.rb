# coding: utf-8
# Assembles a locale's Localizable.strings from an explicit ordered list of
# batch files in /tmp, with duplicate-key dedupe and EN-key parity verification.
#
# Usage:
#   ruby assemble_locale.rb <out_loc> <tmp_prefix> <batch1,batch2,...>
#
# Example:
#   ruby assemble_locale.rb hi hi 1a,1b,2a,2b,3a,3b,4a,4b,5a,5b
#   ruby assemble_locale.rb ms ms 1a,1b,2a,2b,3a_4a,4b,5a,5b
#   ruby assemble_locale.rb pt-PT ptPT 1a,1b,2a,2b,3a_4a,4b_5b

require 'fileutils'
require 'set'

REPO = File.expand_path('.')
OUT_LOC = ARGV[0] or abort "Usage: ruby assemble_locale.rb <out_loc> <tmp_prefix> <batches>"
TMP_PREFIX = ARGV[1] or abort "Usage: ruby assemble_locale.rb <out_loc> <tmp_prefix> <batches>"
BATCHES = (ARGV[2] || '').split(',')
abort "Provide batch list" if BATCHES.empty?

files = BATCHES.map { |b| "/tmp/#{TMP_PREFIX}_batch_#{b}.strings" }
missing = files.reject { |f| File.exist?(f) }
abort "Missing files: #{missing.join(', ')}" unless missing.empty?

puts "Assembling #{OUT_LOC} from #{files.size} batches"
files.each { |f| puts "  #{File.basename(f)}" }

header = <<~HEADER
  /*
    Generator: WooAiTranslation/dev
    Prompt-Version: dev
    Language: #{OUT_LOC}
    Warning: Machine-translated. Spot-checked, non-blocking review.
  */

HEADER

body = files.map { |f| File.read(f, encoding: 'utf-8') }.join("\n")
combined = header + body

KEY_RE = /\A"([^"\\]*(?:\\.[^"\\]*)*)"\s*=\s*"/
lines = combined.lines
seen = Set.new
keep = Array.new(lines.size, true)

i = 0
while i < lines.size
  line = lines[i]
  if line =~ KEY_RE
    key = Regexp.last_match(1)
    if seen.include?(key)
      start = i
      j = i - 1
      while j >= 0 && lines[j] !~ /\A\s*\z/
        start = j
        j -= 1
      end
      (start..i).each { |k| keep[k] = false }
      if i + 1 < lines.size && lines[i + 1] =~ /\A\s*\z/
        keep[i + 1] = false
      end
    else
      seen.add(key)
    end
  end
  i += 1
end

new_lines = lines.each_with_index.select { |_, k| keep[k] }.map(&:first)
removed = lines.size - new_lines.size

out_dir = File.join(REPO, "WooCommerce/Resources/#{OUT_LOC}.lproj")
FileUtils.mkdir_p(out_dir)
out_path = File.join(out_dir, 'Localizable.strings')
File.write(out_path, new_lines.join)

puts ""
puts "  Wrote: #{out_path}"
puts "  Unique keys: #{seen.size}"
puts "  Dedupe removed: #{removed} lines"
puts "  File size: #{File.size(out_path)} bytes"

en_lines = File.readlines(File.join(REPO, 'WooCommerce/Resources/en.lproj/Localizable.strings'), encoding: 'utf-8')
en_keys = Set.new
en_lines.each { |l| en_keys.add($1) if l =~ KEY_RE }

missing_k = en_keys - seen
extra_k = seen - en_keys

puts ""
puts "Verification:"
puts "  EN keys: #{en_keys.size}"
puts "  #{OUT_LOC} unique: #{seen.size}"
puts "  Missing: #{missing_k.size}"
puts "  Extra:   #{extra_k.size}"
if missing_k.size > 0 && missing_k.size <= 20
  missing_k.each { |k| puts "    missing: #{k}" }
end
if extra_k.size > 0 && extra_k.size <= 20
  extra_k.each { |k| puts "    extra: #{k}" }
end
status = (missing_k.empty? && extra_k.empty?) ? 'OK' : 'NEEDS_GAP_FILL'
puts "  STATUS: #{status}"
