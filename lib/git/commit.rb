module Git
  class Commit
    attr_accessor :tree, :message, :parents, :sha

    def initialize(tree, message, *parents)
      self.tree = tree
      self.message = message
      self.parents = parents
      self.sha = (('a'..'f').to_a + (0..9).to_a).sample(7).join
    end
  end

  class File < Struct.new(:path, :content)
  end

  class MergeConflict < StandardError
  end

  class RemoteDoesNotExist < StandardError
  end
end
