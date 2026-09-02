# frozen_string_literal: true

# Destroy confirmation for a Memory or Chronicle, offering two paths: destroy
# the post only, or destroy it and delete any insights left orphaned by it.
class PostDestroyModalComponent < ApplicationComponent
  def initialize(post:, name:)
    @post = post
    @name = name
  end

  attr_reader :post, :name

  def title
    "Destroy #{name}"
  end

  def label
    post.is_a?(Chronicle) ? post.name : post.memo.to_s.truncate(60)
  end

  def destroy_path
    case post
    when Memory then current_team_memory_path(post)
    when Chronicle then current_team_chronicle_path(post)
    end
  end
end
