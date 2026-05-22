# coding: utf-8
# Appends 3 missing Hindi entries and 1 missing Thai entry that the
# sub-agent batches didn't cover (cross-batch boundary edges).
#
# Re-verifies hi and th against EN after appending.

require 'set'

REPO = File.expand_path('.')

GAPS = {
  'hi' => [
    {
      key: 'Enter your store credentials for %@.',
      comment: 'Enter your store credentials for {site url}. Asks the user to enter .org site credentials for their store.',
      value: '%@ के लिए अपनी स्टोर क्रेडेंशियल्स दर्ज करें।'
    },
    {
      key: 'localNotification.AbandonedCampaignCreation.body',
      comment: 'Message on the local notification to remind to continue the Blaze campaign creation.',
      value: 'Blaze के साथ अपने उत्पादों को लाखों लोगों तक पहुंचाएं और अपनी बिक्री बढ़ाएं'
    },
    {
      key: 'localNotification.AbandonedCampaignCreation.title',
      comment: 'Title of the local notification to remind to continue the Blaze campaign creation.',
      value: 'अपनी बिक्री बढ़ाने के बारे में सोच रहे हैं?'
    }
  ],
  'th' => [
    {
      key: 'Enter your store credentials for %@.',
      comment: 'Enter your store credentials for {site url}. Asks the user to enter .org site credentials for their store.',
      value: 'ป้อนข้อมูลรับรองร้านค้าของคุณสำหรับ %@'
    }
  ],
  'pt-PT' => [
    {
      key: 'Enter your store credentials for %@.',
      comment: 'Enter your store credentials for {site url}. Asks the user to enter .org site credentials for their store.',
      value: 'Introduz as credenciais da tua loja para %@.'
    }
  ]
}

KEY_RE = /\A"([^"\\]*(?:\\.[^"\\]*)*)"\s*=\s*"/

GAPS.each do |loc, entries|
  path = File.join(REPO, "WooCommerce/Resources/#{loc}.lproj/Localizable.strings")
  unless File.exist?(path)
    puts "#{loc}: file not found, skipping"
    next
  end
  content = File.read(path, encoding: 'utf-8')

  existing = Set.new
  content.each_line { |l| existing.add($1) if l =~ KEY_RE }

  appended = entries.reject { |e| existing.include?(e[:key]) }
  if appended.empty?
    puts "#{loc}: nothing to fill"
    next
  end

  content = content.dup
  content << "\n" unless content.end_with?("\n\n")

  appended.each do |e|
    content << "/* #{e[:comment]} */\n"
    content << "\"#{e[:key]}\" = \"#{e[:value]}\";\n\n"
  end
  content.rstrip!
  content << "\n"

  File.write(path, content)
  puts "#{loc}: appended #{appended.size} entries"
end

puts ""
puts "=== Verification ==="
en_content = File.read(File.join(REPO, 'WooCommerce/Resources/en.lproj/Localizable.strings'), encoding: 'utf-8')
en_keys = Set.new
en_content.each_line { |l| en_keys.add($1) if l =~ KEY_RE }

%w[hi ms th pt-PT].each do |loc|
  path = File.join(REPO, "WooCommerce/Resources/#{loc}.lproj/Localizable.strings")
  next unless File.exist?(path)
  keys = []
  File.read(path, encoding: 'utf-8').each_line { |l| keys << $1 if l =~ KEY_RE }
  uniq = keys.to_set
  missing = en_keys - uniq
  extra = uniq - en_keys
  dups = keys.size - uniq.size
  status = (missing.empty? && extra.empty? && dups == 0) ? 'OK' : 'FAIL'
  printf("%-3s entries=%d unique=%d missing=%d extra=%d dups=%d %s\n", loc, keys.size, uniq.size, missing.size, extra.size, dups, status)
end
