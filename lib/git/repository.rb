class Repository
  attr_accessor :branches, :commits, :working_directory, :name, :previous_commit_contents, :HEAD

  def initialize(name)
    self.name = name
    self.branches = {:master => nil}
    self.HEAD = :master
    self.commits = {}

    self.working_directory = {
      :staged => [],
      :unstaged => [],
      :untracked => []
    }
  end

  def new_file(path, content)
    file = Git::File.new(path, content)
    untracked << file
    file
  end

  def add(*files)
    files.each do |file|
      untracked.delete file
      unstaged.delete file

      staged << file
    end
  end

  def commit(message)
    take_snapshot_of_contents

    commit = Git::Commit.new(staged, message)

    reset_staging_area
    add_new_commit(commit)

    commit
  end

  def checkout(branch_name, *options)
    branch(branch_name) if options.include?(:b)

    self.HEAD = branch_name
  end

  def reset(new_sha)
    new_commit = commits[new_sha]
    branches[self.HEAD] = new_commit.sha
  end

  def branch(name, *options)
    if options.include?(:D)
      branches.delete name
    else
      branches[name] = branches[self.HEAD]
    end
  end

  def status
    branch = "On branch #{self.HEAD.to_s}\n"

    changes = ''
    if modified_files.empty? and staged.empty?
      changes = "nothing to commit, working directory clean"
    else
      if modified_files.any?
        changes << "Changes not staged for commit:\n\t#{modified_files.map(&:path).join("\n\t")}"
      end
      if staged.any?
        changes << "Changes to be committed:\n\t#{working_directory[:staged].map(&:path).join("\n\t")}"
      end
    end

    branch + changes
  end

  def log
    if commits.any?
      "* #{commits.values.map(&:message).reverse.join "\n* "}"
    else
      ''
    end
  end

  def merge(branch)
    merge_commit_message = "Merge branch #{branch} into #{self.HEAD}"
    first_parent         = branches[branch]
    second_parent        = branches[self.HEAD]
    merge_commit_tree    = commits[first_parent].tree + commits[second_parent].tree

    merge_commit = Git::Commit.new(merge_commit_tree, merge_commit_message)
    merge_commit.parents << first_parent
    merge_commit.parents << second_parent

    commits[merge_commit.sha] = merge_commit

    merge_commit
  end

  def modified_files
    unstaged.select do |file|
      file.content != previous_commit_contents[file.path]
    end
  end

  def staged
    working_directory[:staged]
  end

  def unstaged
    working_directory[:unstaged]
  end

  def untracked
    working_directory[:untracked]
  end

  private

  def take_snapshot_of_contents
    tracked_files = staged + unstaged
    contents = {}
    tracked_files.each do |file|
      contents[file.path] = file.content
    end

    self.previous_commit_contents = contents
  end

  def reset_staging_area
    working_directory[:unstaged] = staged
    working_directory[:staged] = []
  end

  def add_new_commit(commit)
    commit.parents << branches[self.HEAD]
    commits[commit.sha] = commit
    branches[self.HEAD] = commit.sha
  end
end
