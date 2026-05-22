# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'woo_ai_translation/ios_resources'

# Tests for the iOS `.strings` reader/writer. Mirrors the shape of
# `android_resources_test.rb` from the Android engine, scoped to the iOS
# `.strings` format quirks (C-style escapes, no XML, single-value Units).
class IosResourcesTest < Minitest::Test
  include WooAiTranslation

  REPO_ROOT = File.expand_path('../../..', __dir__)
  REAL_EN_PATH = File.join(REPO_ROOT, 'WooCommerce/Resources/en.lproj/Localizable.strings')

  # --- Parser: basics -----------------------------------------------------

  def test_parses_single_entry
    doc = IosResources::Parser.parse(<<~STRINGS)
      "key" = "value";
    STRINGS

    assert_equal 1, doc.units.size
    u = doc.units.first
    assert_equal :string, u.type
    assert_equal 'key', u.name
    assert_equal 'value', u.entries.first[:source]
    assert_equal '', u.comment
  end

  def test_parses_multiple_entries_in_source_order
    doc = IosResources::Parser.parse(<<~STRINGS)
      "a" = "1";
      "b" = "2";
      "c" = "3";
    STRINGS

    assert_equal %w[a b c], doc.units.map(&:name)
    assert_equal %w[1 2 3], doc.units.map { |u| u.entries.first[:source] }
  end

  # --- Parser: comments ---------------------------------------------------

  def test_block_comment_attaches_to_following_key
    doc = IosResources::Parser.parse(<<~STRINGS)
      /* Title of the screen */
      "title" = "Orders";
    STRINGS

    assert_equal 'Title of the screen', doc.units.first.comment
  end

  def test_block_comment_propagates_stickily_until_next_comment
    doc = IosResources::Parser.parse(<<~STRINGS)
      /* Orders section */
      "a" = "1";
      "b" = "2";
      /* Products section */
      "c" = "3";
    STRINGS

    assert_equal 'Orders section', doc.find('a').comment
    assert_equal 'Orders section', doc.find('b').comment
    assert_equal 'Products section', doc.find('c').comment
  end

  def test_multi_line_block_comment
    doc = IosResources::Parser.parse(<<~STRINGS)
      /* Line one
         Line two */
      "key" = "value";
    STRINGS

    assert_match(/Line one/, doc.units.first.comment)
    assert_match(/Line two/, doc.units.first.comment)
  end

  def test_line_comment_is_supported
    doc = IosResources::Parser.parse(<<~STRINGS)
      // Inline note
      "k" = "v";
    STRINGS

    assert_equal 'Inline note', doc.units.first.comment
  end

  # --- Parser: escape decoding -------------------------------------------

  def test_escaped_double_quote_in_value
    doc = IosResources::Parser.parse('"k" = "He said \"hi\"";')
    assert_equal 'He said "hi"', doc.units.first.entries.first[:source]
  end

  def test_escaped_backslash
    doc = IosResources::Parser.parse('"k" = "back\\\\slash";')
    assert_equal 'back\\slash', doc.units.first.entries.first[:source]
  end

  def test_newline_and_tab_escapes
    doc = IosResources::Parser.parse('"k" = "line1\\nline2\\tend";')
    assert_equal "line1\nline2\tend", doc.units.first.entries.first[:source]
  end

  def test_unknown_escape_passes_through_literally
    # `\a` is not a recognised escape -> emit literal `a` (matches Apple parsers).
    doc = IosResources::Parser.parse('"k" = "a\\a";')
    assert_equal 'aa', doc.units.first.entries.first[:source]
  end

  # --- Parser: placeholders preserved ------------------------------------

  def test_placeholders_round_trip_unchanged
    doc = IosResources::Parser.parse('"k" = "Subtotal: %1$@";')
    assert_equal 'Subtotal: %1$@', doc.units.first.entries.first[:source]
  end

  # --- Parser: unquoted keys (InfoPlist.strings format) -----------------

  def test_parses_unquoted_identifier_key
    doc = IosResources::Parser.parse(<<~STRINGS)
      NSCameraUsageDescription = "Camera access for scanning";
      NSPhotoLibraryUsageDescription = "Photo library access";
    STRINGS

    assert_equal 2, doc.units.size
    assert_equal 'NSCameraUsageDescription', doc.units.first.name
    assert_equal 'Camera access for scanning', doc.units.first.entries.first[:source]
    assert_equal 'NSPhotoLibraryUsageDescription', doc.units.last.name
  end

  def test_parses_mixed_quoted_and_unquoted_keys
    doc = IosResources::Parser.parse(<<~STRINGS)
      /* Quoted form */
      "orders.title" = "Orders";
      /* Unquoted form */
      NSCameraUsageDescription = "Camera access";
    STRINGS

    assert_equal %w[orders.title NSCameraUsageDescription], doc.units.map(&:name)
  end

  def test_real_infoplist_strings_round_trip
    info_path = File.join(REPO_ROOT, 'WooCommerce/Resources/en.lproj/InfoPlist.strings')
    skip "no InfoPlist.strings at #{info_path}" unless File.exist?(info_path)

    doc = IosResources::Parser.parse_file(info_path)
    assert_operator doc.units.size, :>=, 10, 'expected >= 10 InfoPlist entries'

    doc.units.each { |u| u.entries.each { |e| e[:value] = e[:source] } }
    Tempfile.create(['ip', '.strings']) do |f|
      f.close
      IosResources::Writer.write(f.path, doc.units, 'en')
      doc2 = IosResources::Parser.parse_file(f.path)
      assert_equal doc.units.size, doc2.units.size
      doc.units.zip(doc2.units) do |a, b|
        assert_equal a.name, b.name
        assert_equal a.entries.first[:source], b.entries.first[:source]
      end
    end
  end

  # --- Parser: error reporting -------------------------------------------

  def test_unterminated_string_raises
    assert_raises(IosResources::Parser::ParseError) do
      IosResources::Parser.parse('"k" = "no close;')
    end
  end

  def test_missing_semicolon_raises
    assert_raises(IosResources::Parser::ParseError) do
      IosResources::Parser.parse('"k" = "v"')
    end
  end

  def test_unterminated_block_comment_raises
    assert_raises(IosResources::Parser::ParseError) do
      IosResources::Parser.parse('/* no close')
    end
  end

  # --- Parser: encoding handling -----------------------------------------

  def test_utf8_bom_is_stripped
    bom = "\xEF\xBB\xBF".b
    content = bom + '"k" = "v";'.b
    Tempfile.create(['t', '.strings']) do |f|
      f.binmode
      f.write(content)
      f.close
      doc = IosResources::Parser.parse_file(f.path)
      assert_equal 'k', doc.units.first.name
    end
  end

  def test_utf16_le_bom_is_decoded
    body = '"k" = "v";'
    bytes = "\xFF\xFE".b + body.encode('UTF-16LE').force_encoding('ASCII-8BIT')
    Tempfile.create(['t', '.strings']) do |f|
      f.binmode
      f.write(bytes)
      f.close
      doc = IosResources::Parser.parse_file(f.path)
      assert_equal 'k', doc.units.first.name
      assert_equal 'v', doc.units.first.entries.first[:source]
    end
  end

  # --- Writer: escape encoding -------------------------------------------

  def test_writer_escapes_double_quote_and_backslash
    assert_equal 'a\\"b\\\\c', IosResources::Writer.escape('a"b\\c')
  end

  def test_writer_escapes_newline_and_tab
    assert_equal 'a\\nb\\tc', IosResources::Writer.escape("a\nb\tc")
  end

  def test_writer_unescape_inverse
    raw = 'a"b\\c' + "\n" + 'd'
    encoded = IosResources::Writer.escape(raw)
    assert_equal raw, IosResources::Writer.unescape(encoded)
  end

  # --- Writer + Parser: idempotent round-trip ----------------------------

  def test_round_trip_synthetic
    input = <<~STRINGS
      /* Orders header */
      "orders.title" = "Orders";
      "orders.empty" = "No orders yet";

      /* Cart */
      "cart.subtotal" = "Subtotal: %1$@";
      "cart.note" = "He said \\"thanks\\"";
    STRINGS

    doc = IosResources::Parser.parse(input)
    # Simulate engine reuse: copy source -> value.
    doc.units.each { |u| u.entries.each { |e| e[:value] = e[:source] } }

    Tempfile.create(['out', '.strings']) do |f|
      f.close
      IosResources::Writer.write(f.path, doc.units, 'xx')
      doc2 = IosResources::Parser.parse_file(f.path)

      assert_equal doc.units.size, doc2.units.size
      doc.units.zip(doc2.units) do |a, b|
        assert_equal a.name, b.name
        assert_equal a.entries.first[:source], b.entries.first[:source]
        assert_equal a.comment, b.comment
      end
    end
  end

  # --- Integration: real Localizable.strings -----------------------------

  def test_real_localizable_strings_round_trip
    skip "real file not present at #{REAL_EN_PATH}" unless File.exist?(REAL_EN_PATH)

    doc = IosResources::Parser.parse_file(REAL_EN_PATH)
    assert_operator doc.units.size, :>, 5000, 'expected ~5,141 entries'

    # Every entry must have a non-empty source (genstrings populates them all).
    empty = doc.units.reject { |u| u.entries.first[:source] && !u.entries.first[:source].empty? }
    assert_empty empty, "found #{empty.size} entries with empty source"

    # Round-trip: write with source as value, re-parse, expect identical shape.
    doc.units.each { |u| u.entries.each { |e| e[:value] = e[:source] } }

    Tempfile.create(['en', '.strings']) do |f|
      f.close
      IosResources::Writer.write(f.path, doc.units, 'en')
      doc2 = IosResources::Parser.parse_file(f.path)

      assert_equal doc.units.size, doc2.units.size

      mismatches = doc.units.zip(doc2.units).reject do |a, b|
        a.name == b.name &&
          a.entries.first[:source] == b.entries.first[:source] &&
          a.comment == b.comment
      end
      assert_empty mismatches.first(5), "round-trip mismatch(es): #{mismatches.size}/#{doc.units.size}"
    end
  end

  # --- Unit semantics -----------------------------------------------------

  def test_unit_is_translatable_by_default
    doc = IosResources::Parser.parse('"k" = "v";')
    assert_predicate doc.units.first, :translatable?
  end

  def test_unit_dup_shell_clears_values
    doc = IosResources::Parser.parse('"k" = "v";')
    u = doc.units.first
    u.entries.first[:value] = 'translated'
    shell = u.dup_shell
    assert_equal u.name, shell.name
    assert_nil shell.entries.first[:value]
    assert_equal 'v', shell.entries.first[:source]
    refute_predicate shell, :fully_translated?
  end

  def test_unit_apply_and_fully_translated
    doc = IosResources::Parser.parse('"a" = "1";' + "\n" + '"b" = "2";')
    a = doc.find('a')
    a.apply!('a' => 'uno')
    assert_predicate a, :fully_translated?
    assert_equal 'uno', a.entries.first[:value]
  end

  def test_source_signature_stable
    doc1 = IosResources::Parser.parse('"k" = "value";')
    doc2 = IosResources::Parser.parse('"k" = "value";')
    assert_equal doc1.units.first.source_signature, doc2.units.first.source_signature
  end
end
