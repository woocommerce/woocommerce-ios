# frozen_string_literal: true

module WooAiTranslation
  # Tier 1 of the shadow-diff calibration tool. Categorizes per-key (EN source,
  # GP human translation, AI proposal) triples into named buckets, produces a
  # reviewer worksheet (Markdown) for entries that need human judgment, and
  # emits a summary report.
  #
  # This module deliberately does NOT make quality judgments. It is mechanical
  # bucketing only. The substantive question — "is AI better, equivalent, or
  # worse than GP for our merchant audience" — is answered by a native-speaker
  # reviewer filling in the worksheet. See README "Shadow-diff calibration"
  # for the full methodology.
  module ShadowDiff
    # Per-key comparison record.
    Entry = Struct.new(
      :key, :en_source, :gp_human, :ai_proposal, :bucket,
      :en_placeholders, :gp_placeholders, :ai_placeholders,
      keyword_init: true
    )

    # Aggregate for one locale. We use `diff_entries` rather than `entries`
    # because Struct.new(:entries, ...) overrides Struct#entries.
    LocaleResult = Struct.new(:locale, :diff_entries, keyword_init: true) do
      def summary
        counts = diff_entries.group_by(&:bucket).transform_values(&:size)
        {
          total: diff_entries.size,
          identical: counts[:identical] || 0,
          cosmetic: counts[:cosmetic] || 0,
          placeholder_mismatch: counts[:placeholder_mismatch] || 0,
          length_significant: counts[:length_significant] || 0,
          substantive: counts[:substantive] || 0
        }
      end

      def bucket(name)
        diff_entries.select { |e| e.bucket == name }
      end
    end

    # Length delta threshold for the `length_significant` bucket. >20% byte
    # difference between GP and AI signals a possible register / verbosity
    # change worth human attention.
    LENGTH_SIGNIFICANT_RATIO = 0.20

    # iOS .strings placeholder syntax. Two flavors:
    #   - Literal percent: `%%` — rendered as a single `%`. MUST be preserved
    #     verbatim across translations (dropping it desyncs printf parsing).
    #     Listed first in the alternation so the regex matches it before the
    #     printf-token branch tries (and fails — `[@dxXos…]+` doesn't accept
    #     `%`, so without the `%%` arm we silently miss it).
    #   - Printf token: %@, %d, %1$@, %2$d, %ld, %lld, %.0f, etc.
    PLACEHOLDER_RE = /%%|%(?:\d+\$)?[@dxXosfFiluL.0-9]+/

    # Sampling policy for the reviewer worksheet. Tier 2 (the human reviewer)
    # reviews 100% of these buckets:
    #   - placeholder_mismatch (hard fail — every one is potentially a bug)
    #   - length_significant   (verify register / verbosity is appropriate)
    # And samples these:
    #   - substantive: max(30, 5% of bucket)  — calibration sample for AI-vs-GP-quality
    #   - identical:   max(10, 0.5% of bucket) — sanity check for training-data memorization
    # Cosmetic entries are counted but not put in the worksheet.
    SAMPLE_POLICY = {
      placeholder_mismatch: { min: nil, ratio: nil }, # 100%
      length_significant: { min: nil, ratio: nil }, # 100%
      substantive: { min: 30, ratio: 0.05 },
      identical: { min: 10, ratio: 0.005 }
    }.freeze

    # Categorize one entry. Pure function; no I/O.
    def self.categorize(en_source:, gp_human:, ai_proposal:)
      en_placeholders = extract_placeholders(en_source)
      gp_placeholders = extract_placeholders(gp_human)
      ai_placeholders = extract_placeholders(ai_proposal)

      # Placeholder mismatch is first-class. Flag whenever AI or GP deviates
      # from the EN source's placeholder set — leaves the reviewer to diagnose
      # which side has the bug.
      return :placeholder_mismatch if ai_placeholders != en_placeholders || gp_placeholders != en_placeholders
      return :identical if gp_human == ai_proposal
      return :cosmetic if normalize_cosmetic(gp_human) == normalize_cosmetic(ai_proposal)

      gp_size = gp_human.to_s.bytesize
      ai_size = ai_proposal.to_s.bytesize
      delta_ratio = (ai_size - gp_size).abs.to_f / [gp_size, 1].max
      return :length_significant if delta_ratio > LENGTH_SIGNIFICANT_RATIO

      :substantive
    end

    # Build an Entry for one key (helper that calls categorize + records the
    # placeholder lists alongside, so the worksheet can render them without
    # re-extraction).
    def self.build_entry(key:, en_source:, gp_human:, ai_proposal:)
      en = extract_placeholders(en_source)
      gp = extract_placeholders(gp_human)
      ai = extract_placeholders(ai_proposal)
      bucket = categorize(en_source: en_source, gp_human: gp_human, ai_proposal: ai_proposal)
      Entry.new(
        key: key, en_source: en_source, gp_human: gp_human, ai_proposal: ai_proposal,
        bucket: bucket,
        en_placeholders: en, gp_placeholders: gp, ai_placeholders: ai
      )
    end

    # Return the subset of `entries` that should go on the reviewer worksheet,
    # per SAMPLE_POLICY. `seed` makes the sampling deterministic so re-runs
    # produce the same calibration sample (useful when comparing before/after
    # an engine change).
    def self.sample_for_worksheet(entries, seed: 42)
      rng = Random.new(seed)
      grouped = entries.group_by(&:bucket)
      out = []

      # 100% of placeholder_mismatch + length_significant
      out.concat(grouped[:placeholder_mismatch] || [])
      out.concat(grouped[:length_significant] || [])

      # Sampled buckets
      %i[substantive identical].each do |bucket|
        bucket_entries = grouped[bucket] || []
        next if bucket_entries.empty?

        policy = SAMPLE_POLICY[bucket]
        size = [policy[:min], (bucket_entries.size * policy[:ratio]).ceil].max
        size = [size, bucket_entries.size].min
        out.concat(bucket_entries.sample(size, random: rng))
      end

      out
    end

    # Normalize for cosmetic comparison: lowercase, collapse whitespace, strip
    # surrounding whitespace. Intentionally does NOT strip punctuation — a
    # diff in "Hello!" vs "Hello." is semantically interesting enough to be
    # `substantive` rather than `cosmetic`.
    def self.normalize_cosmetic(text)
      text.to_s.downcase.gsub(/\s+/, ' ').strip
    end

    # Sorted list of placeholders in `text`. Sorting makes the comparison
    # order-independent (a translation may reorder placeholders for grammar,
    # which is fine as long as the set is preserved).
    def self.extract_placeholders(text)
      text.to_s.scan(PLACEHOLDER_RE).sort
    end

    # --- Worksheet + report writers ---

    # Render a per-locale reviewer worksheet as Markdown. The reviewer adds
    # their judgment in the verdict column (`[ ] AI better / [ ] equivalent /
    # [ ] GP better`) and saves the file alongside their notes.
    #
    # `seed` controls the random sample selection — MUST match the seed used
    # for `sample_for_worksheet` when building the AI-judge advisory, or the
    # advisory column will be sparse (judge ran on different entries than
    # the worksheet renders).
    def self.render_worksheet(locale_result, ai_judge_advisory: nil, seed: 42)
      header_lines = render_worksheet_header(locale_result)
      table_lines = render_worksheet_table(locale_result, ai_judge_advisory: ai_judge_advisory, seed: seed)
      (header_lines + table_lines).join("\n")
    end

    # Render a one-locale summary section as Markdown.
    def self.render_summary(locale_result)
      s = locale_result.summary
      pct = ->(n) { s[:total].zero? ? '0.0%' : format('%.1f%%', n.to_f / s[:total] * 100) }
      <<~MD
        ## #{locale_result.locale}

        | Bucket | Count | Share |
        |---|---:|---:|
        | identical | #{s[:identical]} | #{pct.call(s[:identical])} |
        | cosmetic | #{s[:cosmetic]} | #{pct.call(s[:cosmetic])} |
        | placeholder_mismatch | #{s[:placeholder_mismatch]} | #{pct.call(s[:placeholder_mismatch])} |
        | length_significant | #{s[:length_significant]} | #{pct.call(s[:length_significant])} |
        | substantive | #{s[:substantive]} | #{pct.call(s[:substantive])} |
        | **total** | **#{s[:total]}** | **100%** |
      MD
    end

    # ---

    def self.render_worksheet_header(locale_result)
      [
        "# Shadow-diff worksheet — #{locale_result.locale}",
        '',
        '_Generated by the WooAiTranslation shadow-diff tool. Reviewer fills in the **Verdict** column for each row._',
        '',
        '**How to use this worksheet**:',
        '- For each row, judge the AI proposal against the GP human translation **for the WooCommerce merchant audience**.',
        "- Mark the verdict column: `AI better` / `equivalent` / `GP better`. If you can't decide, mark `unsure` and leave a note.",
        '- The question is *comparative*, not "is AI correct". Sometimes both are fine; mark `equivalent`.',
        '- Placeholder-mismatch rows are HARD FAILS — every one must be inspected. Look at the placeholder columns to see which side deviates from the EN source.',
        '- Length-significant rows are flagged when AI and GP differ by >20% in byte length. Often signals a register / verbosity change.',
        '',
        ''
      ]
    end

    def self.render_worksheet_table(locale_result, ai_judge_advisory: nil, seed: 42)
      entries = sample_for_worksheet(locale_result.diff_entries, seed: seed)
      cols = base_columns
      cols << '| Judge (advisory) ' unless ai_judge_advisory.nil?
      cols << '| Verdict | Reviewer notes |'
      lines = [cols.join, render_separator(ai_judge_advisory)]

      entries.each do |entry|
        lines << render_row(entry, ai_judge_advisory)
      end

      lines
    end

    def self.base_columns
      ['| Key | Bucket | EN | GP human | AI proposal | EN ph | GP ph | AI ph ']
    end

    def self.render_separator(ai_judge_advisory)
      sep = '|---|---|---|---|---|---|---|---'
      sep += '|---' unless ai_judge_advisory.nil?
      sep += '|---|---|'
      sep
    end

    def self.render_row(entry, ai_judge_advisory)
      cells = [
        '',
        escape_md(entry.key),
        entry.bucket.to_s,
        escape_md(entry.en_source),
        escape_md(entry.gp_human),
        escape_md(entry.ai_proposal),
        entry.en_placeholders.join(' '),
        entry.gp_placeholders.join(' '),
        entry.ai_placeholders.join(' ')
      ]
      cells << (ai_judge_advisory[entry.key] || '—') unless ai_judge_advisory.nil?
      cells << ' [ ] AI better / [ ] equivalent / [ ] GP better'
      cells << ''
      "#{cells.join(' | ')}|"
    end

    # Escape pipe + newline so a translation containing `|` or `\n` doesn't
    # break the Markdown table. Keep it minimal — we want the reviewer to see
    # the actual translation, just not have it explode the table layout.
    def self.escape_md(text)
      text.to_s.gsub('|', '\\|').gsub("\n", '<br>')
    end
  end
end
