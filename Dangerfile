# frozen_string_literal: true

# --- Translation Context Plugin (test) ---
require 'tmpdir'

def install_txcontext!
  txcontext_root = Dir.mktmpdir('txcontext')
  txcontext_gem_home = File.join(txcontext_root, 'gems')
  install_env = {
    'GEM_HOME' => txcontext_gem_home,
    'GEM_PATH' => txcontext_gem_home
  }

  Bundler.with_unbundled_env do
    system('git', 'clone', '--depth', '1', 'https://github.com/iangmaia/txcontext.git', txcontext_root) or
      raise 'Failed to clone txcontext'

    Dir.chdir(txcontext_root) do
      system('gem', 'build', 'txcontext.gemspec', '-o', 'txcontext.gem') or
        raise 'Failed to build txcontext gem'
      system(install_env, 'gem', 'install', '--no-document', '--force',
             '--install-dir', txcontext_gem_home, 'txcontext.gem') or
        raise 'Failed to install txcontext gem'
    end
  end

  gem_libs = Dir.glob(File.join(txcontext_gem_home, 'gems', '*', 'lib'))
  txcontext_lib = gem_libs.find { |lib_path| File.basename(File.dirname(lib_path)).start_with?('txcontext-') }
  raise 'Failed to locate txcontext gem lib directory' unless txcontext_lib

  $LOAD_PATH.unshift(txcontext_lib) unless $LOAD_PATH.include?(txcontext_lib)
  (gem_libs - [txcontext_lib]).each do |lib_path|
    $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
  end

  require 'txcontext'
end

begin
  install_txcontext!
rescue StandardError => e
  warn("txcontext bootstrap failed: #{e.message}")
end

# Import the translation context checker plugin from the dangermattic branch
branch_base = 'https://raw.githubusercontent.com/Automattic/dangermattic/iangmaia/add-translation-context-plugin/lib/dangermattic/plugins'
danger.import_plugin("#{branch_base}/translation_context_checker.rb")

translation_context_checker.check_context_suggestions(
  translations: 'WooCommerce/Resources/en.lproj/Localizable.strings',
  source_paths: ['WooCommerce/Classes/'],
  provider: :anthropic,
  model: 'claude-sonnet-4-6',
  report_type: :warning
)
# --- End Translation Context Plugin ---

github.dismiss_out_of_range_messages

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

view_changes_checker.check

pr_size_checker.check_diff_size(
  max_size: 300,
  file_selector: ->(path) { !path.include?('Tests/') }
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
