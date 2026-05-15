# frozen_string_literal: true

# Pure-Ruby helpers for the `create_release_notes_pr` Fastlane lane.
#
# These helpers are deliberately stateless and free of Fastlane / network
# dependencies so they can be exercised by unit tests without touching
# OpenAI, GitHub, or git.
module ReleaseNotesPRHelper # rubocop:disable Metrics/ModuleLength
  PREFERRED_RELEASE_NOTES_MAX_LENGTH = 350

  module_function

  # Validates the version string passed to the lane.
  #
  # Accepts `MAJOR.MINOR` and `MAJOR.MINOR.PATCH` shapes only.
  #
  # @param version [String]
  # @return [String, nil] error message, or nil if valid
  def validate_version(version)
    return 'version is required' if version.nil? || version.to_s.strip.empty?
    return "Invalid version: #{version}" unless version.match?(/\A\d+\.\d+(\.\d+)?\z/)

    nil
  end

  # @param version [String]
  # @return [String] the upstream release branch name (e.g. `release/24.8`)
  def release_branch_name(version)
    "release/#{version}"
  end

  # @param version [String]
  # @return [String] the deterministic automation branch name (e.g. `release-notes/24.8`)
  def automation_branch_name(version)
    "release-notes/#{version}"
  end

  # Builds the user-facing question for `openai_ask`. Used in conjunction with
  # release-toolkit's predefined `:release_notes` system prompt and the
  # `validate_release_notes_length` tool: the model checks drafts via the tool
  # and the handler validates length externally, replying with
  # `{ ok: true, length: }` on success, or `{ ok: false, length:, max:, cut_at_least?, reason? }`
  # otherwise — `cut_at_least` is set when the draft is too long, `reason` is set for
  # other rejections (e.g. an empty draft). The model iterates until accepted.
  #
  # @param version [String]
  # @param items_text [String] pre-filtered release-note items (one bullet per
  #   line). Internal-only entries and GitHub URL/PR-number tokens are expected
  #   to be stripped by the caller via `items_for_ai_prompt`.
  # @return [String]
  def build_ai_release_notes_prompt(version:, items_text:)
    <<~QUESTION
      Act like a mobile app marketer preparing release notes for the App Store.
      Write effective release notes for WooCommerce iOS #{version} that help merchants understand what changed in this update — in a voice that feels like a helpful person talking to a shop owner, not a changelog.

      Each item is prefixed by an optional priority marker — `[***]` highest, `[**]` medium, `[*]` standard — that you can use to emphasize the most important changes.

      ### Non-negotiable (accuracy)
      These rules are absolute. Warmth never justifies bending them.
      - Only use the provided items.
      - Do not invent features, fixes, or benefits.
      - Every clause must trace back to a provided item. Do not add generic claims like "smoother experience", "streamlined interface", or "improved performance" unless an item explicitly says so.
      - Do not mention the release version or version number in the output.
      - Write a single, unique paragraph — not a point-by-point list.
      - The final text must be #{PREFERRED_RELEASE_NOTES_MAX_LENGTH} characters or fewer, including spaces.
      - Preserve correct grammar and spelling. Do not drop letters from words, omit articles, or invent abbreviations to fit the character limit. If a draft is too long, restructure or remove a phrase or item rather than mutilating individual words.

      ### Style (aim for warmth within these limits)
      - Write in a warm, direct second-person voice — "you", "your store", "your customers". Sound like a person, not a release log.
      - Active, benefit-led voice. Lead with what the merchant can now do, not with passive "X has been added". Prefer "Switch between Gross, Net, and Total revenue" over "Revenue switching has been added".
      - You may open with a short, natural lead-in **as long as it names a real change** — e.g. "Selling on iPad just got easier:" is fine because the items back it up; "We've been hard at work!" is not, because it says nothing.
      - You may use **one** warm touch — either an opener or a closing line, not both. A closing line is fine if it refers to a specific change. It must not be a generic call-to-action ("Update now!", "Try it today", "Explore these features"). When in doubt, end on a substantive change.
      - Plain benefit words are welcome: "now", "easier", "no longer", and "faster" — but only "faster" when an item literally describes a speed improvement. The hype ban is about *unsupported intensifiers* and stock launch words: avoid "lightning-fast", "faster than ever", "seamless", "supercharged", "amazingly", "incredibly", "brand new", "introducing", "we're thrilled". State the change directly, warmly.
      - Use the available character budget as room to write naturally. Short item lists do not need to be terse — a 120-character draft that could comfortably be 220 is usually too clipped. Spend the space on a fuller, friendlier sentence, never on padding.
      - Write for WooCommerce merchants, not developers — avoid engineering jargon.

      ### Worked example (tone target)
      Items: fixed barcode scanning not working after completing a payment; onboarding tasks now show after switching stores.
      - **Good (warm and accurate):** "A couple of fixes to keep your day moving: barcode scanning in Point of Sale now keeps working after you take a payment, and your store setup tasks stay put when you switch stores."
      - **Too flat:** "Barcode scanning works after payment. Onboarding tasks show after switching stores."
      - **Too far (invents tone and benefit):** "We've supercharged Point of Sale! Update now for a seamless, lightning-fast experience."
      Match the cadence and merchant-led framing of the "Good" example — do not reuse its phrasing.

      ### Validation
      Check your draft by calling the `validate_release_notes_length` tool with the proposed text.
      The tool will reply with `{ ok: true, length: }` if the draft fits within the character limit, or with `{ ok: false, length:, max:, cut_at_least?, reason? }` otherwise — `cut_at_least` is included when the draft is too long, `reason` is included for other rejections (e.g. an empty draft).
      When the tool replies `ok: false`, shorten the draft by at least `cut_at_least` characters when present, or address the `reason` otherwise, then call the tool again.
      Keep iterating until the tool replies `ok: true`. Submit every draft — including the final accepted one — through the `validate_release_notes_length` tool. Do not include the release-notes text in your plain-text reply; the calling code reads the accepted draft from the tool argument, not from your final message.

      Items:
      #{items_text}
    QUESTION
  end

  # Prepends (or replaces) the editorialized `## <version>` block in
  # `CHANGELOG.md`.
  #
  # If `## <version>` already exists in the changelog, replaces that block
  # (the heading line, its paragraph, and the trailing blank-line separator)
  # — making the lane idempotent on re-runs and tolerating manual edits.
  #
  # Otherwise, inserts a new block right after the `-->` line that closes
  # the file's header comment. If no header comment is found, the block is
  # prepended at the top.
  #
  # @param existing [String] current contents of CHANGELOG.md
  # @param version [String] e.g. "24.6"
  # @param copy [String] merchant-facing paragraph (no trailing newline)
  # @return [String] new changelog contents
  def prepend_or_replace_changelog_entry(existing:, version:, copy:)
    new_block = "## #{version}\n#{copy}\n\n"

    # Replace an existing block matching this exact version, if present.
    version_block_regex = /^## #{Regexp.escape(version)}\n.*?(?=^## |\z)/m
    return existing.sub(version_block_regex, new_block) if existing.match?(version_block_regex)

    # Insert after the `-->` line that closes the file's header comment.
    comment_close_regex = /^-->\n/
    return existing.sub(comment_close_regex, "-->\n#{new_block}") if existing.match?(comment_close_regex)

    # Fallback: no header comment — prepend at the very top.
    "#{new_block}#{existing}"
  end

  # Validates non-empty AI output.
  #
  # @param generated_notes [String]
  # @return [String, nil] error message, or nil if valid
  def validate_generated_release_notes_not_empty(generated_notes)
    return 'OpenAI returned empty release notes' if generated_notes.nil? || generated_notes.strip.empty?

    nil
  end

  # Parses the raw release-notes block into structured source items, skipping
  # `[Internal]` entries.
  #
  # Expected line shape:
  #   - [**] Improved barcode scanner reading accuracy [https://github.com/woocommerce/woocommerce-ios/pull/12345]
  #
  # @param raw_items [String]
  # @return [Array<Hash>] each item has keys `:priority, :text, :url, :number,
  #   :type`. `:priority` carries the raw marker string (`[*]`, `[**]`, `[***]`)
  #   or `nil` if absent; `:url, :number, :type` are `nil` when the line has no
  #   GitHub link. Downstream enrichment in the Fastfile may add `:author_login`
  #   and `:author_url` keys; this method itself does not populate them.
  def parse_source_items(raw_items)
    return [] if raw_items.nil?

    raw_items.lines.filter_map { |line| parse_source_item_line(line) }
  end

  # Parses a single release-notes line into a source-item hash, or returns nil
  # if the line should be skipped (blank, `[Internal]`, or empty after parsing).
  #
  # `[Internal]` is filtered after stripping the optional `[*]`/`[**]` priority
  # marker, so entries like `- [*] [Internal] …` are also skipped. The marker
  # (e.g. `[*]`, `[**]`, `[***]`) is captured on the result as `:priority` so
  # callers can reproduce it (the AI prompt uses it as a relative-importance
  # hint).
  def parse_source_item_line(line)
    content = line.strip.sub(/\A-\s*/, '')

    priority_match = content.match(/\A(?<marker>\[\*+\])\s*/)
    priority = priority_match&.[](:marker)
    content = content.sub(/\A\[\*+\]\s*/, '')

    return nil if content.empty?
    return nil if content.match?(/\A\[Internal\]/i)

    text, url_info = split_text_and_url(content)
    return nil if text.empty?

    { priority: priority, text: text, url: url_info[:url], number: url_info[:number], type: url_info[:type] }
  end

  # Formats already-parsed source items as a bullet list suitable for the AI
  # prompt: each line is `- [priority] text` (or just `- text` when no priority
  # marker is present). Internal-only entries and GitHub URL/PR-number tokens
  # are stripped *upstream* during parsing (see `parse_source_item_line` and
  # `split_text_and_url`); this method does not filter anything.
  def items_for_ai_prompt(source_items)
    source_items.map do |item|
      item[:priority] ? "- #{item[:priority]} #{item[:text]}" : "- #{item[:text]}"
    end.join("\n")
  end

  # Splits the trailing `[https://github.com/.../pull/123]` or
  # `(https://github.com/.../pull/123)` token off the line. Real-world
  # RELEASE-NOTES entries use both forms, sometimes followed by trailing
  # sentence punctuation (e.g. `[…].`), and sometimes contain multiple
  # comma-separated URLs in the same bracket (e.g.
  # `[…/pull/15819, https://…/pull/15821]`) — we capture the first URL.
  # Returns `[text, { url:, number:, type: }]` (number/type may be nil).
  def split_text_and_url(content)
    match = content.match(%r{\s*[\[(](?<url>https?://github\.com/[^\s\]),]+)[^\])]*[\])][.,;!?]*\s*\z})
    return [content, { url: nil, number: nil, type: nil }] unless match

    text = content.sub(match[0], '').rstrip
    [text, parse_github_url(match[:url])]
  end

  # @return [Hash] url/number/type for a github.com/{org}/{repo}/(pull|issues)/{n} URL
  def parse_github_url(url)
    parts = url.match(%r{github\.com/[^/]+/[^/]+/(?<kind>pull|issues)/(?<num>\d+)})
    return { url: url, number: nil, type: nil } unless parts

    { url: url, number: Integer(parts[:num]), type: parts[:kind] == 'issues' ? 'issue' : 'pull' }
  end

  # Renders the Markdown table of source items for the PR body. Excludes any
  # `team` column.
  #
  # @param source_items [Array<Hash>]
  # @return [String]
  def source_items_markdown_table(source_items)
    return '_No source items parsed._' if source_items.nil? || source_items.empty?

    rows = source_items.map { |item| source_item_table_row(item) }
    [
      '| Source item | PR / Issue | Author |',
      '| --- | --- | --- |',
      *rows
    ].join("\n")
  end

  def source_item_table_row(item)
    "| #{item[:text]} | #{format_source_link(item)} | #{format_author(item)} |"
  end

  def format_source_link(item)
    return '—' unless item[:url] && item[:number]

    "[##{item[:number]}](#{item[:url]})"
  end

  def format_author(item)
    return '—' unless item[:author_login] && item[:author_url]

    "[@#{item[:author_login]}](#{item[:author_url]})"
  end

  # Builds the PR body. No team-name column.
  #
  # @param version [String]
  # @param generated_notes [String]
  # @param source_items [Array<Hash>] enriched with optional :author_login, :author_url
  # @param ai_prompt [String] the user-question portion sent to `openai_ask`
  #   on the first attempt (rendered in a collapsible block for transparency)
  # @return [String]
  def build_release_notes_pr_body(version:, generated_notes:, source_items:, ai_prompt:)
    <<~BODY
      Created by ReleasesV2 automation.

      This PR updates the WooCommerce iOS release notes for `#{version}`.

      Please review the AI-generated copy before merging.

      ## AI-generated release notes

      > #{generated_notes}

      Character count: #{generated_notes.length} / #{PREFERRED_RELEASE_NOTES_MAX_LENGTH}

      <details>
      <summary>Prompt sent to OpenAI (first attempt)</summary>

      ```
      #{ai_prompt.strip}
      ```

      </details>

      ## Source items used

      #{source_items_markdown_table(source_items)}

      ## Review checklist

      - [ ] Generated notes only describe items from this release.
      - [ ] No internal-only work is mentioned.
      - [ ] No GitHub links, PR numbers, issue numbers, or engineering jargon appear in `release_notes.txt`.
      - [ ] Copy is accurate and merchant-facing.
      - [ ] Copy is #{PREFERRED_RELEASE_NOTES_MAX_LENGTH} characters or fewer.
    BODY
  end

  # @param version [String]
  # @return [String] PR title
  def pr_title(version)
    "Update release notes for #{version}"
  end
end
