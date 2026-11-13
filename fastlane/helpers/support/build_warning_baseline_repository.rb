# frozen_string_literal: true

# Real local Git repositories for baseline ref selection and worktree cleanup.
module BuildWarningBaselineRepository
  def prepare_repository
    git(@directory, 'init', '--bare', '--initial-branch=release/testing', remote)
    git(@directory, 'init', '--initial-branch=release/testing', author)
    install_base_setup
    git(author, 'add', '.')
    commit('Initial baseline')
    publish_repository
    @base_commit = git(author, 'rev-parse', 'HEAD')
  end

  def publish_repository
    git(author, 'branch', 'feature')
    git(author, 'remote', 'add', 'origin', remote)
    git(author, 'push', 'origin', 'release/testing', 'feature')
    git(@directory, 'clone', '--branch', 'feature', remote, @checkout)
  end

  def install_base_setup
    setup = File.join(author, '.buildkite/commands/shared-set-up.sh')
    FileUtils.mkdir_p(File.dirname(setup))
    File.write(setup, "#!/bin/bash\nexec baseline-setup\n")
    File.chmod(0o755, setup)
  end

  def advance_base_with_restricted_mapping
    git(@checkout, 'config', 'remote.origin.fetch', '+refs/heads/feature:refs/remotes/origin/feature')
    commit('Advance baseline')
    @base_commit = git(author, 'rev-parse', 'HEAD')
    git(author, 'branch', '--force', 'feature', @base_commit)
    git(author, 'push', 'origin', 'release/testing', 'feature')
    git(@checkout, 'fetch', 'origin', 'feature')
    git(@checkout, 'checkout', '--detach', 'FETCH_HEAD')
    @base_commit
  end

  def remove_base_tracking_ref
    git(@checkout, 'update-ref', '-d', 'refs/remotes/origin/release/testing')
  end

  def git(directory, *)
    output, error, status = Open3.capture3(environment, 'git', '-C', directory, *, unsetenv_others: true)
    raise "Git fixture failed: #{error}" unless status.success?

    output.strip
  end

  def commit(message)
    git(author, '-c', 'user.name=Baseline Test', '-c', 'user.email=baseline@example.invalid',
        'commit', '--allow-empty', '-m', message)
  end

  def remote
    File.join(@directory, 'remote.git')
  end

  def author
    File.join(@directory, 'author')
  end
end
