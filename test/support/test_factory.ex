defmodule EctoTurbo.TestFactory do
  @moduledoc """
  Exmachina for EctoTurbo
  """

  use ExMachina.Ecto, repo: EctoTurbo.TestRepo

  alias EctoTurbo.Schemas.{Category, Post, Reply}

  @doc """
  Inserts a category object.
  """
  @spec category_factory() :: Category.t()
  def category_factory do
    %Category{
      name: sequence(:name, &"category-name#{&1}")
      # posts: build_pair(:post)
    }
  end

  @doc """
  Inserts a post object
  """
  @spec post_factory() :: Post.t()
  def post_factory do
    %Post{
      name: sequence(:name, &"post-name#{&1}"),
      body: sequence(:body, &"post-body#{&1}"),
      available: true,
      category: build(:category),
      replies: build_pair(:reply)
    }
  end

  @doc """
  Inserts a reply object.
  """
  @spec reply_factory() :: Reply.t()
  def reply_factory do
    %Reply{
      content: sequence(:content, &"content-#{&1}")
      # post: build(:post)
    }
  end
end
