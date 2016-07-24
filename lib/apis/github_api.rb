require 'octokit'

# Wrapper for dealing with github's api
class GithubApi
  def initialize
    @github = Octokit::Client.new(
      login: GITHUB_USER,
      password: GITHUB_TOKEN
    )
  end

  def identifier_exists?(identifier)
    branch_exists?(identifier) || commit_exists?(identifier)
  end

  def branch_exists?(branch)
    begin
      @github.get_branch(GITHUB_REPO, branch).present?
      return true
    rescue Octokit::NotFound => e
      return false
    end
  end

  def commit_exists?(commit_hash)
    begin
      @github.commit(GITHUB_REPO, commit_hash).present?
      return true
    rescue Octokit::NotFound => e
      return false
    end
  end

  # Gets a short-lived url to a tarball of the repo code.  It's not clear exactly
  # how short-lived, but github's docs say:
  # > Note: For private repositories, these links are temporary and expire quickly.
  def get_tarball_url(branch)
    puts "tarballing #{branch}"
    @github.archive_link(GITHUB_REPO, ref: branch)
  end
end
