# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../bin/translate_locale'

# Regression coverage for the two data-loss bugs fixed in the engine PR:
#   1. --incremental / no-manifest runs wiped existing translations because the
#      reload read [:value] (always nil after parse) instead of [:source].
#   2. --limit smoke runs (and any partial pass) clobbered the committed locale
#      by writing the subset straight to the real path, before verification.
class TranslateLocaleTest < Minitest::Test
  NOOP_LOGGER = ->(_msg) {}

  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  # --- helpers ---------------------------------------------------------------

  def write_strings(path, pairs)
    body = pairs.map { |k, v| %("#{k}" = "#{v}";) }.join("\n")
    File.write(path, "#{body}\n")
    path
  end

  # A parsed *target* unit carries its translation in [:source] (the parser
  # leaves [:value] nil regardless of file role). An EN-derived unit is the same
  # shape with value still nil, awaiting translation.
  def en_unit(name, source)
    u = WooAiTranslation::IosResources::Unit.new(type: :string, name: name, attributes: {}, comment: '')
    u.entries = [{ id: name, source: source, value: nil }]
    u
  end

  def translated_unit(name, source, value)
    u = en_unit(name, source)
    u.entries.first[:value] = value
    u
  end

  FakeTranslator = Struct.new(:mapping) do
    def translate(locale:, items:, model:)
      items.to_h { |i| [i[:id], mapping.fetch(i[:id], "#{i[:source]}::#{locale}::#{model}")] }
    end
  end

  def tmp_artifacts_in(dir)
    Dir.glob(File.join(dir, '*.tmp.*'))
  end

  # --- finding 1: incremental / reload reads [:source] -----------------------

  def test_merge_with_existing_projects_existing_translations_onto_en_units
    # Given a target locale whose keys are already translated (values differ
    # from EN), and EN-derived units with empty values.
    target = write_strings(File.join(@dir, 'pl.strings'),
                           [%w[a Anuluj], %w[b Zapisz]])
    en_units = [en_unit('a', 'Cancel'), en_unit('b', 'Save')]

    # When we reload the target to preserve unchanged translations.
    merged = merge_with_existing(en_units, target)

    # Then each unit keeps its previously-translated value (not "" — that was
    # the [:value] bug that dropped the whole locale).
    assert_equal 'Anuluj', merged[0].entries.first[:value]
    assert_equal 'Zapisz', merged[1].entries.first[:value]
  end

  def test_filter_missing_units_skips_already_translated_keys_without_manifest
    # Given a fully-translated target and no manifest (the PR #17220 bootstrap
    # path that has to read existing locale files).
    target = write_strings(File.join(@dir, 'pl.strings'),
                           [%w[a Anuluj], %w[b Zapisz]])
    en_units = [en_unit('a', 'Cancel'), en_unit('b', 'Save')]

    # When we ask which keys still need translation.
    needs = filter_missing_units(en_units, target, logger: NOOP_LOGGER, manifest: nil)

    # Then nothing does — the bug made this return ALL keys (re-translating the
    # entire locale on every run).
    assert_empty needs
  end

  def test_filter_missing_units_flags_keys_absent_from_target
    # Given a target missing key 'b'.
    target = write_strings(File.join(@dir, 'pl.strings'), [%w[a Anuluj]])
    en_units = [en_unit('a', 'Cancel'), en_unit('b', 'Save')]

    # When filtering.
    needs = filter_missing_units(en_units, target, logger: NOOP_LOGGER, manifest: nil)

    # Then only the absent key needs translation.
    assert_equal ['b'], needs.map(&:name)
  end

  # --- finding 2: write-then-verify + smoke-run clobber guard -----------------

  def test_write_translations_smoke_run_leaves_committed_locale_untouched
    # Given a complete committed locale on disk.
    output = write_strings(File.join(@dir, 'Localizable.strings'),
                           [%w[a AA], %w[b BB], %w[c CC]])
    original = File.read(output)

    # When a smoke run renders only a subset.
    wrote = write_translations!(
      output_path: output,
      units_for_write: [translated_unit('a', 'a', 'AA')],
      expected_names: Set.new(%w[a b c]),
      locale: 'pl', logger: NOOP_LOGGER, smoke_run: true
    )

    # Then it reports "not written", the file is untouched, and no temp file
    # is left behind.
    refute wrote
    assert_equal original, File.read(output)
    assert_empty tmp_artifacts_in(@dir)
  end

  def test_write_translations_refuses_partial_real_write_and_preserves_file
    # Given a complete committed locale.
    output = write_strings(File.join(@dir, 'Localizable.strings'),
                           [%w[a AA], %w[b BB], %w[c CC]])
    original = File.read(output)

    # When a real (non-smoke) write would drop keys the source still has.
    err = assert_raises(RuntimeError) do
      write_translations!(
        output_path: output,
        units_for_write: [translated_unit('a', 'a', 'AA')],
        expected_names: Set.new(%w[a b c]),
        locale: 'pl', logger: NOOP_LOGGER, smoke_run: false
      )
    end

    # Then it aborts loudly and the committed file is preserved intact.
    assert_match(/Refusing to write/, err.message)
    assert_equal original, File.read(output)
    assert_empty tmp_artifacts_in(@dir)
  end

  def test_write_translations_installs_complete_set_atomically
    # Given no existing file and a complete set of translated units.
    output = File.join(@dir, 'Localizable.strings')
    units = [translated_unit('a', 'a', 'AA'),
             translated_unit('b', 'b', 'BB'),
             translated_unit('c', 'c', 'CC')]

    # When a real write installs them.
    wrote = write_translations!(
      output_path: output,
      units_for_write: units,
      expected_names: Set.new(%w[a b c]),
      locale: 'pl', logger: NOOP_LOGGER, smoke_run: false
    )

    # Then the file lands with every key and no temp residue remains.
    assert wrote
    reparsed = WooAiTranslation::IosResources::Parser.parse_file(output)
    assert_equal Set.new(%w[a b c]), Set.new(reparsed.units.map(&:name))
    assert_empty tmp_artifacts_in(@dir)
  end

  # --- finding 2: end-to-end via translate_file ------------------------------

  def test_translate_file_limit_does_not_overwrite_existing_locale
    # Given an EN source and an existing translated locale.
    en = write_strings(File.join(@dir, 'en.strings'),
                       [%w[a Cancel], %w[b Save], %w[c Delete]])
    output = write_strings(File.join(@dir, 'Localizable.strings'),
                           [%w[a Anuluj], %w[b Zapisz], %w[c Usun]])
    original = File.read(output)

    # When we run a --limit 1 smoke pass.
    translated, missing, errors = translate_file(
      input_path: en, output_path: output,
      translator: FakeTranslator.new({}), locale: 'pl', model: 'm',
      limit: 1, logger: NOOP_LOGGER, incremental: false,
      manifest: nil, escalation_model: nil
    )

    # Then it translates the single key in memory but leaves the locale on disk
    # exactly as committed.
    assert_equal 1, translated
    assert_empty missing
    assert_empty errors
    assert_equal original, File.read(output)
    assert_empty tmp_artifacts_in(@dir)
  end

  def test_translate_file_limit_does_not_persist_manifest
    # Given an EN source, an existing locale, and a fresh manifest.
    en = write_strings(File.join(@dir, 'en.strings'),
                       [%w[a Cancel], %w[b Save], %w[c Delete]])
    output = write_strings(File.join(@dir, 'Localizable.strings'),
                           [%w[a Anuluj], %w[b Zapisz], %w[c Usun]])
    manifest_path = File.join(@dir, 'pl.json')
    manifest = WooAiTranslation::Manifest.new(locale: 'pl', path: manifest_path)

    # When a smoke run translates a subset.
    translate_file(
      input_path: en, output_path: output,
      translator: FakeTranslator.new({}), locale: 'pl', model: 'm',
      limit: 1, logger: NOOP_LOGGER, incremental: false,
      manifest: manifest, escalation_model: nil
    )

    # Then nothing is recorded or persisted — a smoke run must not make the
    # manifest claim keys we never wrote.
    assert_equal 0, manifest.size
    refute File.exist?(manifest_path)
  end

  def test_translate_file_smoke_run_without_limit_writes_nothing
    # Given a source, an existing locale, and a manifest — modelling the
    # InfoPlist pass of a --limit smoke run: it carries no per-file limit, but
    # the overall run is a smoke test, so smoke_run is threaded in independently.
    en = write_strings(File.join(@dir, 'en.strings'),
                       [%w[a Cancel], %w[b Save]])
    output = write_strings(File.join(@dir, 'Localizable.strings'),
                           [%w[a Anuluj], %w[b Zapisz]])
    original = File.read(output)
    manifest_path = File.join(@dir, 'pl.json')
    manifest = WooAiTranslation::Manifest.new(locale: 'pl', path: manifest_path)

    # When a no-limit pass is explicitly marked as part of a smoke run.
    translated, = translate_file(
      input_path: en, output_path: output,
      translator: FakeTranslator.new({}), locale: 'pl', model: 'm',
      limit: nil, logger: NOOP_LOGGER, incremental: false,
      manifest: manifest, escalation_model: nil, smoke_run: true
    )

    # Then it translates in memory but neither writes the locale nor persists the
    # manifest — the bug was that limit:nil forced a real write + save! here.
    assert_equal 2, translated
    assert_equal original, File.read(output)
    assert_equal 0, manifest.size
    refute File.exist?(manifest_path)
    assert_empty tmp_artifacts_in(@dir)
  end

  def test_translate_file_full_run_writes_every_key
    # Given an EN source and no existing locale.
    en = write_strings(File.join(@dir, 'en.strings'),
                       [%w[a Cancel], %w[b Save], %w[c Delete]])
    output = File.join(@dir, 'Localizable.strings')

    # When we run a full (no-limit) bootstrap.
    translated, = translate_file(
      input_path: en, output_path: output,
      translator: FakeTranslator.new({}), locale: 'pl', model: 'm',
      limit: nil, logger: NOOP_LOGGER, incremental: false,
      manifest: nil, escalation_model: nil
    )

    # Then every key is translated and written.
    assert_equal 3, translated
    reparsed = WooAiTranslation::IosResources::Parser.parse_file(output)
    assert_equal Set.new(%w[a b c]), Set.new(reparsed.units.map(&:name))
    assert_empty tmp_artifacts_in(@dir)
  end
end
