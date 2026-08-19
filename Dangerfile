# frozen_string_literal: true

github.dismiss_out_of_range_messages

unless respond_to?(:translation_context_checker)
  require 'bundler'
  require 'tmpdir'

  gem_dir = Dir.mktmpdir('i18n-context-generator-gems')
  installed = Bundler.with_unbundled_env do
    system(
      'gem', 'install', 'i18n-context-generator', '--version', '0.5.2',
      '--no-document', '--install-dir', gem_dir
    )
  end
  raise 'Could not install i18n-context-generator 0.5.2' unless installed

  Dir.glob(File.join(gem_dir, 'gems', '*', 'lib')).each { |path| $LOAD_PATH.unshift(path) }
  require 'i18n_context_generator'

  Dir.mktmpdir('dangermattic-translation-context') do |plugin_dir|
    cloned = system(
      'git', 'clone', '--quiet', '--depth', '1', '--branch', 'iangmaia/add-translation-context-plugin',
      'https://github.com/Automattic/dangermattic.git', plugin_dir
    )
    raise 'Could not load Dangermattic translation context plugin' unless cloned

    danger.import_plugin(File.join(plugin_dir, 'lib/dangermattic/plugins/translation_context_checker.rb'))
  end
end

translation_context_checker.check_resource_changes(
  source_paths: ['WooCommerce/Classes/'],
  resource_paths: 'WooCommerce/Resources/en.lproj/Localizable.strings',
  inline_mode: :resource_suggestion,
  report_type: :warning
)

# `files: []` forces rubocop to scan all files, not just the ones modified in the PR
rubocop.lint(files: [], force_exclusion: true, inline_comment: true, fail_on_inline_comment: true, include_cop_names: true)

manifest_pr_checker.check_all_manifest_lock_updated

ios_release_checker.check_core_data_model_changed
ios_release_checker.check_release_notes_and_app_store_strings

# skip remaining checks if we're in a release-process PR
if github.pr_labels.include?('Releases')
  message('This PR has the `Releases` label: some checks will be skipped.')
  return
end

common_release_checker.check_internal_release_notes_changed(report_type: :message)

ios_release_checker.check_modified_translations_on_release_branch

tracks_checker.check_tracks_changes(
  tracks_files: [
    'WooAnalyticsStat.swift'
  ],
  tracks_usage_matchers: [
    /AnalyticsTracker\.track/
  ],
  tracks_label: 'category: tracks'
)

# Warn when Action enums are modified without updating mock handlers
action_files = git.modified_files.select { |f| f.start_with?('Modules/Sources/Yosemite/Actions/') }
mock_handler_files = git.modified_files.select { |f| f.start_with?('Modules/Sources/Yosemite/Model/Mocks/') }

if action_files.any? && mock_handler_files.empty?
  warn(
    "Action enum(s) modified (`#{action_files.map { |f| File.basename(f) }.join('`, `')}`) " \
    'without updating mock handlers. If new action cases were added, update the corresponding ' \
    'MockActionHandler in `Modules/Sources/Yosemite/Model/Mocks/ActionHandlers/` to avoid ' \
    'breaking screenshot tests.'
  )
end

view_changes_checker.check

pr_size_checker.check_diff_size(
  max_size: 300,
  file_selector: ->(path) { !path.include?('Tests/') },
  # Exclude blank lines and Swift comment lines from the size metric
  line_selector: lambda { |line|
    stripped = line.strip
    !(stripped.empty? || stripped.start_with?('//', '/*', '*', '*/'))
  }
)

# skip remaining checks if the PR is still a Draft
if github.pr_draft?
  message('This PR is still a Draft: some checks will be skipped.')
  return
end

labels_checker.check(
  do_not_merge_labels: ['status: do not merge'],
  required_labels: [//],
  required_labels_error: 'PR requires at least one label.'
)

# runs the milestone check if this is not a WIP feature and the PR is against the main branch or the release branch
if (github_utils.main_branch? || github_utils.release_branch?) && !github_utils.wip_feature?
  report_type = github.pr_labels.include?('milestone-not-required') || github.pr_labels.include?('status: feature-flagged') ? :message : :error
  milestone_checker.check_milestone_due_date(
    days_before_due: 2,
    report_type_if_no_milestone: report_type
  )
end
