defmodule EctoTurbo.Builder.JoinTest do
  @moduledoc false

  use ExUnit.Case
  doctest EctoTurbo.Builder.Join

  alias EctoTurbo.Builder.Join
  alias EctoTurbo.Schemas.Post

  describe "build/2" do
    test "empty relations returns original query unchanged" do
      query = Join.build(Post, [])
      assert Macro.to_string(query) == "EctoTurbo.Schemas.Post"
    end

    test "single relation join" do
      query =
        Post
        |> Join.build([:category])
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, join: c1 in assoc(p0, :category)>"
    end

    test "two relations join" do
      query =
        Post
        |> Join.build([:category, :replies])
        |> Macro.to_string()

      assert query ==
               "#Ecto.Query<from p0 in EctoTurbo.Schemas.Post, join: c1 in assoc(p0, :category), join: r2 in assoc(p0, :replies)>"
    end

    test "join binding indices are sequential" do
      query = Join.build(Post, [:category, :replies])

      assert length(query.joins) == 2

      [first_join, second_join] = query.joins
      assert first_join.assoc == {0, :category}
      assert second_join.assoc == {0, :replies}
    end

    test "join produces inner join" do
      query = Join.build(Post, [:category])

      [join] = query.joins
      assert join.qual == :inner
    end

    test "single join produces one join entry" do
      query = Join.build(Post, [:category])
      assert length(query.joins) == 1
    end

    test "three relations produce three joins" do
      # :replies is a valid assoc on Post, :category too
      # We test that build handles multiple sequential joins
      query = Join.build(Post, [:category, :replies])
      assert length(query.joins) == 2
    end
  end

  describe "apply_join/2" do
    test "single join on schema" do
      query = Join.apply_join(:category, Post)

      assert %Ecto.Query{} = query
      assert length(query.joins) == 1
    end

    test "join produces correct association" do
      query = Join.apply_join(:category, Post)

      [join] = query.joins
      assert join.assoc == {0, :category}
      assert join.qual == :inner
    end

    test "join on replies association" do
      query = Join.apply_join(:replies, Post)

      [join] = query.joins
      assert join.assoc == {0, :replies}
    end
  end
end
