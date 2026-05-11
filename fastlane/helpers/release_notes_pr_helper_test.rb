# frozen_string_literal: true

# Pure-Ruby unit tests for ReleaseNotesPRHelper. Uses Ruby's stdlib Minitest so
# no extra gems are required.
#
# Run:
#   ruby fastlane/helpers/release_notes_pr_helper_test.rb

require 'minitest/autorun'
require_relative 'release_notes_pr_helper'

# Unit tests for ReleaseNotesPRHelper.
class ReleaseNotesPRHelperTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  Helper = ReleaseNotesPRHelper

  # --- Version validation ----------------------------------------------------

  def test_validate_version_accepts_major_minor
    assert_nil Helper.validate_version('24.8')
  end

  def test_validate_version_accepts_major_minor_patch
    assert_nil Helper.validate_version('24.8.1')
  end

  def test_validate_version_rejects_empty
    refute_nil Helper.validate_version('')
    refute_nil Helper.validate_version(nil)
  end

  def test_validate_version_rejects_invalid_strings
    refute_nil Helper.validate_version('twenty-four')
    refute_nil Helper.validate_version('24')
    refute_nil Helper.validate_version('24.8.1.2')
    refute_nil Helper.validate_version('v24.8')
  end

  # --- Branch helpers --------------------------------------------------------

  def test_release_branch_name
    assert_equal 'release/24.8', Helper.release_branch_name('24.8')
    assert_equal 'release/24.8.1', Helper.release_branch_name('24.8.1')
  end

  def test_automation_branch_name
    assert_equal 'release-notes/24.8', Helper.automation_branch_name('24.8')
    assert_equal 'release-notes/24.8.1', Helper.automation_branch_name('24.8.1')
  end

  # --- Prompt builder --------------------------------------------------------

  def test_prompt_includes_required_rules
    prompt = Helper.build_ai_release_notes_prompt(version: '24.8', items_text: '- [*] Foo')
    [
      'Act like a mobile app marketer',
      'App Store',
      'help merchants understand what changed',
      'priority marker',
      'Only use the provided items.',
      'Do not invent features, fixes, or benefits.',
      'Write for WooCommerce merchants',
      'Do not write it point by point',
      'single, unique paragraph',
      'Do not mention the release version or version number',
      "The final text must be #{Helper::PREFERRED_RELEASE_NOTES_MAX_LENGTH} characters or fewer",
      'Return only the final release notes text'
    ].each do |fragment|
      assert_includes prompt, fragment, "Expected prompt to include `#{fragment}`"
    end
    assert_includes prompt, '24.8'
    assert_includes prompt, '- [*] Foo'
  end

  def test_retry_prompt_mentions_previous_response
    previous = 'A' * (Helper::PREFERRED_RELEASE_NOTES_MAX_LENGTH + 50)
    prompt = Helper.build_ai_release_notes_prompt(
      version: '24.8',
      items_text: '- [*] Foo',
      previous_response: previous
    )
    assert_includes prompt, 'The previous response was too long'
    assert_includes prompt, "Rewrite it to be #{Helper::PREFERRED_RELEASE_NOTES_MAX_LENGTH} characters or fewer"
    assert_includes prompt, previous.length.to_s
  end

  # --- CHANGELOG editorial entry --------------------------------------------

  def changelog_with_header
    <<~MD
      <!--
      Contains editorialized release notes. Raw release notes should go into `RELEASE-NOTES.txt`.
      -->
      ## 24.5
      Previous version copy.

      ## 24.4
      Older version copy.
    MD
  end

  def test_prepend_changelog_entry_inserts_after_header_comment
    result = Helper.prepend_or_replace_changelog_entry(
      existing: changelog_with_header,
      version: '24.6',
      copy: 'Latest merchant copy.'
    )

    expected = <<~MD
      <!--
      Contains editorialized release notes. Raw release notes should go into `RELEASE-NOTES.txt`.
      -->
      ## 24.6
      Latest merchant copy.

      ## 24.5
      Previous version copy.

      ## 24.4
      Older version copy.
    MD
    assert_equal expected, result
  end

  def test_prepend_changelog_entry_replaces_existing_version_block
    existing = <<~MD
      <!--
      Contains editorialized release notes. Raw release notes should go into `RELEASE-NOTES.txt`.
      -->
      ## 24.6
      Stale draft copy.

      ## 24.5
      Previous version copy.
    MD

    result = Helper.prepend_or_replace_changelog_entry(
      existing: existing,
      version: '24.6',
      copy: 'Updated final copy.'
    )

    expected = <<~MD
      <!--
      Contains editorialized release notes. Raw release notes should go into `RELEASE-NOTES.txt`.
      -->
      ## 24.6
      Updated final copy.

      ## 24.5
      Previous version copy.
    MD
    assert_equal expected, result
  end

  def test_prepend_changelog_entry_replaces_when_target_is_last_block
    existing = <<~MD
      <!--
      Header.
      -->
      ## 24.6
      Stale.
    MD

    result = Helper.prepend_or_replace_changelog_entry(
      existing: existing,
      version: '24.6',
      copy: 'Fresh.'
    )

    assert_includes result, "## 24.6\nFresh.\n\n"
    refute_includes result, 'Stale.'
  end

  def test_prepend_changelog_entry_does_not_match_partial_version_prefix
    existing = <<~MD
      <!--
      Header.
      -->
      ## 24.6.1
      Hotfix copy.

      ## 24.6
      Original copy.
    MD

    result = Helper.prepend_or_replace_changelog_entry(
      existing: existing,
      version: '24.6',
      copy: 'New original copy.'
    )

    # 24.6 entry replaced; 24.6.1 entry untouched.
    assert_includes result, "## 24.6.1\nHotfix copy.\n\n"
    assert_includes result, "## 24.6\nNew original copy.\n\n"
    refute_includes result, 'Original copy.'
  end

  def test_prepend_changelog_entry_falls_back_to_top_when_no_header_comment
    existing = "## 24.5\nOlder.\n"

    result = Helper.prepend_or_replace_changelog_entry(
      existing: existing,
      version: '24.6',
      copy: 'Newer.'
    )

    assert result.start_with?("## 24.6\nNewer.\n\n")
    assert_includes result, "## 24.5\nOlder.\n"
  end

  # --- Length validation -----------------------------------------------------

  def test_empty_response_fails_validation
    refute_nil Helper.validate_generated_release_notes_not_empty('')
    refute_nil Helper.validate_generated_release_notes_not_empty('   ')
    refute_nil Helper.validate_generated_release_notes_not_empty(nil)
    assert_nil Helper.validate_generated_release_notes_not_empty('hi')
  end

  # --- Source item parsing ---------------------------------------------------

  def test_parse_source_items_extracts_text_url_and_pr_number
    raw = "- [**] Improved barcode scanner reading accuracy [https://github.com/woocommerce/woocommerce-ios/pull/12345]\n"
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_equal 'Improved barcode scanner reading accuracy', items.first[:text]
    assert_equal 'https://github.com/woocommerce/woocommerce-ios/pull/12345', items.first[:url]
    assert_equal 12_345, items.first[:number]
    assert_equal 'pull', items.first[:type]
  end

  def test_parse_source_items_handles_issue_links
    raw = "- [*] Fixed coupon bug [https://github.com/woocommerce/woocommerce-ios/issues/999]\n"
    items = Helper.parse_source_items(raw)
    assert_equal 'issue', items.first[:type]
    assert_equal 999, items.first[:number]
  end

  def test_parse_source_items_filters_internal
    raw = <<~RAW
      - [*] Polished order creation [https://github.com/woocommerce/woocommerce-ios/pull/12346]
      - [Internal] Refactor release config [https://github.com/woocommerce/woocommerce-ios/pull/12344]
    RAW
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_equal 'Polished order creation', items.first[:text]
  end

  def test_parse_source_items_filters_internal_after_priority_marker
    raw = <<~RAW
      - [*] Polished order creation [https://github.com/woocommerce/woocommerce-ios/pull/12346]
      - [*] [Internal] Refactor login flow [https://github.com/woocommerce/woocommerce-ios/pull/15444]
      - [***] [Internal] Start AB test [https://github.com/woocommerce/woocommerce-ios/pull/8744]
    RAW
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_equal 'Polished order creation', items.first[:text]
  end

  def test_parse_source_items_accepts_parenthesised_url
    raw = "- [*] Fixed possible sync issue in POS (https://github.com/woocommerce/woocommerce-ios/pull/16423)\n"
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_equal 'Fixed possible sync issue in POS', items.first[:text]
    assert_equal 'https://github.com/woocommerce/woocommerce-ios/pull/16423', items.first[:url]
    assert_equal 16_423, items.first[:number]
    assert_equal 'pull', items.first[:type]
  end

  def test_parse_source_items_tolerates_trailing_punctuation_after_url
    raw = "- [*] Order Creation: Resolved exit confirmation issue [https://github.com/woocommerce/woocommerce-ios/pull/15394].\n"
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_equal 'Order Creation: Resolved exit confirmation issue', items.first[:text]
    assert_equal 'https://github.com/woocommerce/woocommerce-ios/pull/15394', items.first[:url]
    assert_equal 15_394, items.first[:number]
    assert_equal 'pull', items.first[:type]
  end

  def test_parse_source_items_captures_first_url_of_multi_link_entry
    raw = "- [**] Shipping Labels: Support UPS extra services [https://github.com/woocommerce/woocommerce-ios/pull/15819, https://github.com/woocommerce/woocommerce-ios/pull/15821]\n"
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_equal 'Shipping Labels: Support UPS extra services', items.first[:text]
    assert_equal 'https://github.com/woocommerce/woocommerce-ios/pull/15819', items.first[:url]
    assert_equal 15_819, items.first[:number]
    assert_equal 'pull', items.first[:type]
  end

  def test_parse_source_items_handles_missing_url
    raw = "- [*] A small fix\n"
    items = Helper.parse_source_items(raw)
    assert_equal 1, items.size
    assert_nil items.first[:url]
    assert_nil items.first[:number]
  end

  def test_parse_source_items_captures_priority_marker
    raw = <<~RAW
      - [*] Standard item
      - [**] Higher priority
      - [***] Highest priority
      - No marker item
    RAW
    items = Helper.parse_source_items(raw)
    assert_equal 4, items.size
    assert_equal '[*]', items[0][:priority]
    assert_equal '[**]', items[1][:priority]
    assert_equal '[***]', items[2][:priority]
    assert_nil items[3][:priority]
  end

  # --- AI prompt input formatting -------------------------------------------

  def test_items_for_ai_prompt_strips_urls_and_includes_priority
    items = [
      { priority: '[*]', text: 'Standard fix' },
      { priority: '[**]', text: 'Important change' },
      { priority: nil, text: 'Plain item' }
    ]
    text = Helper.items_for_ai_prompt(items)
    expected = [
      '- [*] Standard fix',
      '- [**] Important change',
      '- Plain item'
    ].join("\n")
    assert_equal expected, text
  end

  def test_items_for_ai_prompt_excludes_internal_via_upstream_filter
    raw = <<~RAW
      - [*] User-facing fix [https://github.com/woocommerce/woocommerce-ios/pull/1]
      - [*] [Internal] Refactor [https://github.com/woocommerce/woocommerce-ios/pull/2]
    RAW
    text = Helper.items_for_ai_prompt(Helper.parse_source_items(raw))
    assert_equal '- [*] User-facing fix', text
    refute_includes text, '[Internal]'
    refute_includes text, 'github.com'
    refute_includes text, 'Refactor'
  end

  # --- PR body / table -------------------------------------------------------

  def test_table_includes_clickable_author_link
    items = [{
      text: 'Improved barcode scanner reading accuracy',
      url: 'https://github.com/woocommerce/woocommerce-ios/pull/12345',
      number: 12_345,
      type: 'pull',
      author_login: 'some-user',
      author_url: 'https://github.com/some-user'
    }]
    table = Helper.source_items_markdown_table(items)
    assert_includes table, '[#12345](https://github.com/woocommerce/woocommerce-ios/pull/12345)'
    assert_includes table, '[@some-user](https://github.com/some-user)'
  end

  def test_table_renders_em_dash_when_author_missing
    items = [{
      text: 'Foo',
      url: 'https://github.com/woocommerce/woocommerce-ios/pull/1',
      number: 1,
      type: 'pull'
    }]
    table = Helper.source_items_markdown_table(items)
    assert_match(/\| Foo \| \[#1\]\(.*\) \| — \|/, table)
  end

  def test_table_has_no_team_column
    items = [{ text: 'Foo', url: 'u', number: 1, type: 'pull' }]
    table = Helper.source_items_markdown_table(items)
    refute_includes table, 'Team'
  end

  def test_pr_body_contains_required_sections
    body = Helper.build_release_notes_pr_body(
      version: '24.8',
      generated_notes: 'Short merchant copy.',
      source_items: [{
        text: 'Improved barcode scanner reading accuracy',
        url: 'https://github.com/woocommerce/woocommerce-ios/pull/12345',
        number: 12_345,
        type: 'pull',
        author_login: 'some-user',
        author_url: 'https://github.com/some-user'
      }],
      ai_prompt: "Act like a mobile app marketer…\n\nItems:\n- [*] Improved barcode scanner reading accuracy"
    )

    assert_includes body, 'AI-generated release notes'
    assert_includes body, 'Short merchant copy.'
    assert_includes body, "Character count: 20 / #{Helper::PREFERRED_RELEASE_NOTES_MAX_LENGTH}"
    assert_includes body, 'Source items used'
    assert_includes body, '[#12345](https://github.com/woocommerce/woocommerce-ios/pull/12345)'
    assert_includes body, '[@some-user](https://github.com/some-user)'
    assert_includes body, 'Review checklist'
    refute_includes body, 'Team'
  end

  def test_pr_body_includes_collapsible_ai_prompt
    body = Helper.build_release_notes_pr_body(
      version: '24.8',
      generated_notes: 'Short merchant copy.',
      source_items: [],
      ai_prompt: "Act like a mobile app marketer preparing release notes for the App Store.\n\nRules:\n- Only use the provided items.\n\nItems:\n- [*] Foo"
    )

    assert_includes body, '<details>'
    assert_includes body, 'Prompt sent to OpenAI'
    assert_includes body, 'Act like a mobile app marketer preparing release notes'
    assert_includes body, '- [*] Foo'
  end

  def test_pr_title
    assert_equal 'Update release notes for 24.8', Helper.pr_title('24.8')
    assert_equal 'Update release notes for 24.8.1', Helper.pr_title('24.8.1')
  end
end
