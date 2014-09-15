require 'spec_helper'

describe Repository do
  let(:repo) { Repository.new 'name' }

  context 'week 1' do

    it 'has a name' do
      expect(repo.name).to eq 'name'
    end

    it 'starts with an empty list of commits and no files' do
      expect(repo.commits).to be_empty
      expect(repo.staged).to be_empty
      expect(repo.unstaged).to be_empty
      expect(repo.untracked).to be_empty
    end

    describe '#add' do
      it 'starts tracking files' do
        file = repo.new_file '/file/path', 'content'

        expect(repo.staged.length).to be 0
        expect(repo.unstaged.length).to be 0
        expect(repo.untracked.length).to be 1

        repo.add file

        expect(repo.staged.length).to be 1
        expect(repo.unstaged.length).to be 0
        expect(repo.untracked.length).to be 0
      end

      it 'knows which files have been modified' do
        file = repo.new_file '/file/path', 'content'
        repo.add file
        repo.commit 'commit message'
        file.content = 'new content'

        expect(repo.modified_files).to include file
      end

      it 'stages a file' do
        file = repo.new_file '/file/path', 'content'
        repo.add file
        repo.commit 'commit message'
        file.content = 'new content'

        expect(repo.staged.length).to be 0
        expect(repo.unstaged.length).to be 1
        expect(repo.untracked.length).to be 0

        repo.add file

        expect(repo.staged.length).to be 1
        expect(repo.unstaged.length).to be 0
        expect(repo.untracked.length).to be 0
      end
    end

    describe '#branch' do
      it 'starts on a master branch that has no commits' do
        expect(repo.HEAD).to eq :master
        expect(repo.branches[:master]).to be_nil
      end

      it 'can create a new branch' do
        file = repo.new_file '/file/path', 'content'
        repo.add file
        repo.commit 'commit message'

        repo.branch :feature

        expect(repo.branches).to include :master
        expect(repo.branches).to include :feature
        expect(repo.branches[:feature]).to eq repo.branches[:master]
      end

      it 'can delete a branch with the :D option' do
        repo.branch :feature
        repo.branch :feature, :D

        expect(repo.branches).not_to include :feature
      end
    end

    describe '#commit' do
      it 'records the contents of tracked files so it can determine when they are modified' do
        path = '/first/file'
        repo.working_directory[:staged] = [Git::File.new(path, 'content')]
        repo.commit 'commit message'

        expect(repo.previous_commit_contents[path]).to eq 'content'
      end

      it 'keeps track of all commits' do
        repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]
        commit = repo.commit 'commit message'

        expect(repo.commits).to include commit
      end

      it 'unstages files after the commit is created' do
        repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]

        expect(repo.staged.length).to be 1
        expect(repo.unstaged.length).to be 0
        expect(repo.untracked.length).to be 0

        repo.commit 'commit message'

        expect(repo.staged.length).to be 0
        expect(repo.unstaged.length).to be 1
        expect(repo.untracked.length).to be 0
      end

      it 'adds commits to the current branch' do
        repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]
        commit = repo.commit 'commit message'

        expect(repo.branches[:master]).to eq commit

        newer_commit = repo.commit 'commit message 2'
        expect(repo.branches[:master]).to eq newer_commit
      end

      it 'keeps track of the parent commit' do
        first_commit = double 'commit'
        repo.branches[:master] = first_commit
        repo.working_directory[:staged] = [Git::File.new('file/path', 'content')]
        second_commit = repo.commit 'commit message'

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

      it 'can create a branch with the :b option' do
        repo.checkout :new_branch, :b
        expect(repo.branches).to include :new_branch
        expect(repo.HEAD).to eq :new_branch
      end
    end

    describe '#status' do
      it 'shows the current branch' do
        expect(repo.status).to include 'On branch master'
        repo.branch :new_branch
        repo.checkout :new_branch
        expect(repo.status).to include 'On branch new_branch'
      end

      it 'shows when the working directory is clean' do
        expect(repo.status).to include 'nothing to commit, working directory clean'
      end

      it 'shows the status files' do
        file1 = repo.new_file '/file1/path', 'content'
        file2 = repo.new_file '/file2/path', 'content'
        repo.add file1, file2
        repo.commit 'commit message'
        file1.content = 'new content 1'
        file2.content = 'new content 2'

        expect(repo.status).to include "Changes not staged for commit:"
        expect(repo.status).to include file1.path, file2.path
        expect(repo.status).to include file2.path

        repo.add file1, file2
        expect(repo.status).to include "Changes to be committed:"
        expect(repo.status).to include file1.path
        expect(repo.status).to include file2.path

        repo.commit 'commit message 2'
        expect(repo.status).to include "nothing to commit"
      end
    end

    describe '#log' do
      it 'starts out empty' do
        expect(repo.log).to be_empty
      end

      it 'shows a commit' do
        file = repo.new_file '/file/path', 'content'
        repo.add file
        repo.commit 'first message'
        file.content = 'new content'
        repo.add file
        repo.commit 'second message'

        expect(repo.log).to include '* first message'
        expect(repo.log).to include '* second message'
      end
    end

    describe '#reset' do
      it 'points the current branch to a specified commit' do
        file = repo.new_file '/file/path', 'content'
        repo.add file
        first_commit = repo.commit 'first message'
        file.content = 'new content'
        repo.add file
        repo.commit 'second message'

        repo.reset(first_commit.sha)

        expect(repo.branches[repo.HEAD]).to eq first_commit
      end
    end
  end
end
