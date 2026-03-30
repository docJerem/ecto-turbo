defmodule EctoTurbo.Hooks.PaginateTest do
  @moduledoc false

  use ExUnit.Case
  doctest EctoTurbo.Hooks.Paginate

  alias EctoTurbo.Hooks.Paginate

  describe "current_pages/2" do
    test "returns [1] when total_pages is 0" do
      assert Paginate.current_pages(1, 0) == [1]
    end

    test "returns [1] when total_pages is negative" do
      assert Paginate.current_pages(1, -1) == [1]
    end

    test "returns [1] when total_pages is 1" do
      assert Paginate.current_pages(1, 1) == [1]
    end

    test "returns full list for small page counts" do
      assert Paginate.current_pages(1, 3) == [1, 2, 3]
      assert Paginate.current_pages(2, 3) == [1, 2, 3]
      assert Paginate.current_pages(3, 3) == [1, 2, 3]
    end

    test "includes left ellipsis when current_page > 5" do
      result = Paginate.current_pages(7, 20)
      assert "..." in result
      assert hd(result) == 1
    end

    test "includes right ellipsis when current_page < total_pages - 4" do
      result = Paginate.current_pages(3, 20)
      assert List.last(result) == 20
      assert "..." in result
    end

    test "includes both ellipses in the middle" do
      result = Paginate.current_pages(10, 20)
      assert result == [1, "...", 8, 9, 10, 11, 12, "...", 20]
    end

    test "first page of many" do
      result = Paginate.current_pages(1, 20)
      assert result == [1, 2, 3, "...", 20]
    end

    test "last page of many" do
      result = Paginate.current_pages(20, 20)
      assert result == [1, "...", 18, 19, 20]
    end

    test "page 5 includes bridge to page 2" do
      result = Paginate.current_pages(5, 20)
      assert result == [1, 2, 3, 4, 5, 6, 7, "...", 20]
    end

    test "page total_pages - 4 includes bridge to second-to-last" do
      result = Paginate.current_pages(16, 20)
      assert result == [1, "...", 14, 15, 16, 17, 18, 19, 20]
    end

    test "current_page out of bounds is clamped" do
      result = Paginate.current_pages(0, 10)
      assert hd(result) == 1

      result = Paginate.current_pages(99, 10)
      assert List.last(result) == 10
    end
  end
end
