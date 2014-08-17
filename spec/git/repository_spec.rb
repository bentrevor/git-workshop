require 'spec_helper'

describe Repository do
  let(:repo) { Repository.new 'name', 'owner' }

  it 'has an owner and a name' do
    expect(repo.name).to eq 'name'
    expect(repo.owner).to eq 'owner'
  end

  it 'starts with an empty list of commits and no files' do
    expect(repo.commits).to be_empty
    expect(repo.working_directory[:staged]).to be_empty
    expect(repo.working_directory[:unstaged]).to be_empty
    expect(repo.working_directory[:untracked]).to be_empty
  end

  describe '#add' do
    it 'starts tracking files' do
      file = repo.new_file '/file/path', 'content'

      expect(repo.working_directory[:staged].length).to be 0
      expect(repo.working_directory[:unstaged].length).to be 0
      expect(repo.working_directory[:untracked].length).to be 1

      repo.add file

      expect(repo.working_directory[:staged].length).to be 1
      expect(repo.working_directory[:unstaged].length).to be 0
      expect(repo.working_directory[:untracked].length).to be 0
    end

    it 'knows which files have been modified' do
      file = repo.new_file '/file/path', 'content'
      repo.add file
      repo.commit 'author'
      file.content = 'new content'

      expect(repo.modified_files).to include file
    end
  end

  describe '#branch' do
    it 'starts on a master branch that has no commits' do
      expect(repo.HEAD).to eq :master
      expect(repo.branches[:master]).to be_nil
    end

    it 'can create a new branch' do
      repo.branch 'feature'

      expect(repo.branches).to include :master
      expect(repo.branches).to include :feature
    end
  end

  describe '#commit' do
    it 'records the contents of tracked files so it can determine when they are modified' do
      path = '/first/file'
      repo.working_directory[:staged] = [Git::File.new(path, 'content')]
      repo.commit 'author'

      expect(repo.previous_commit_contents[path]).to eq 'content'
    end

    it 'keeps track of all commits' do
      repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]
      commit = repo.commit 'author'

      expect(repo.commits).to include commit
    end

    it 'unstages files after the commit is created' do
      repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]

      expect(repo.working_directory[:staged].length).to be 1
      expect(repo.working_directory[:unstaged].length).to be 0
      expect(repo.working_directory[:untracked].length).to be 0

      repo.commit 'author'

      expect(repo.working_directory[:staged].length).to be 0
      expect(repo.working_directory[:unstaged].length).to be 1
      expect(repo.working_directory[:untracked].length).to be 0
    end

    it 'adds commits to the current branch' do
      repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]
      commit = repo.commit 'author'

      expect(repo.branches[:master]).to eq commit

      newer_commit = repo.commit 'author'
      expect(repo.branches[:master]).to eq newer_commit
    end

    it 'keeps track of the parent commit' do
      first_commit = double 'commit'
      repo.branches[:master] = first_commit
      repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]
      second_commit = repo.commit 'author'

      expect(second_commit.parents).to include first_commit
    end
  end

  describe '#checkout' do
    it 'changes the current branch' do
      expect(repo.HEAD).to eq :master
      repo.branch :new_branch
      repo.checkout :new_branch
      expect(repo.HEAD).to eq :new_branch
    end
  end
end
