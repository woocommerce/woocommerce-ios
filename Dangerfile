# frozen_string_literal: true

# --- Translation Context Plugin (test) ---
require 'tmpdir'

def install_i18n_context_generator!
  gem_root = Dir.mktmpdir('i18n-context-generator')
  gem_home = File.join(gem_root, 'gems')
  install_i18n_context_generator_gem!(gem_root: gem_root, gem_home: gem_home)
  load_i18n_context_generator_gem!(gem_home)
end

def install_i18n_context_generator_gem!(gem_root:, gem_home:)
  install_env = {
    'GEM_HOME' => gem_home,
    'GEM_PATH' => gem_home
  }

  Bundler.with_unbundled_env do
    system('git', 'clone', '--depth', '1', 'https://github.com/Automattic/i18n-context-generator.git', gem_root) or
      raise 'Failed to clone i18n-context-generator'

    Dir.chdir(gem_root) do
      system('gem', 'build', 'i18n-context-generator.gemspec', '-o', 'i18n-context-generator.gem') or
        raise 'Failed to build i18n-context-generator gem'
      system(install_env, 'gem', 'install', '--no-document', '--force',
             '--install-dir', gem_home, 'i18n-context-generator.gem') or
        raise 'Failed to install i18n-context-generator gem'
    end
  end
end

def load_i18n_context_generator_gem!(gem_home)
  gem_libs = Dir.glob(File.join(gem_home, 'gems', '*', 'lib'))
  generator_lib = find_i18n_context_generator_lib(gem_libs)
  raise 'Failed to locate i18n-context-generator gem lib directory' unless generator_lib

  prepend_load_path(generator_lib)
  (gem_libs - [generator_lib]).each do |lib_path|
    prepend_load_path(lib_path)
  end

  require 'i18n_context_generator'
end

def find_i18n_context_generator_lib(gem_libs)
  gem_libs.find { |lib_path| File.basename(File.dirname(lib_path)).start_with?('i18n-context-generator-') }
end

def prepend_load_path(lib_path)
  $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
end

begin
  install_i18n_context_generator!
rescue StandardError => e
  warn("i18n-context-generator bootstrap failed: #{e.message}")
end

# Import the translation context checker plugin from the dangermattic branch
branch_base = 'https://raw.githubusercontent.com/Automattic/dangermattic/iangmaia/add-translation-context-plugin/lib/dangermattic/plugins'
danger.import_plugin("#{branch_base}/common/inline_markdown_poster.rb")
danger.import_plugin("#{branch_base}/translation_context_checker.rb")

translation_context_checker.check_context_suggestions(
  discovery_mode: :source,
  source_paths: ['WooCommerce/Classes/'],
  provider: :anthropic,
  model: 'claude-sonnet-4-6',
  report_type: :warning,
  inline_mode: :source_suggestion
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
