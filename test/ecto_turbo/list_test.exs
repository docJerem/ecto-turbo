defmodule EctoTurbo.ListTest do
  use ExUnit.Case, async: true

  alias EctoTurbo.List, as: TList

  describe "new/3 pagination metadata" do
    test "keeps next_page and prev_page nil on a single page" do
      paginate = %{
        current_page: 1,
        current_pages: [1],
        per_page: 10,
        total_count: 3,
        total_pages: 1,
        next_page: nil,
        prev_page: nil
      }

      %TList{pagination: pagination} = TList.new([:a, :b, :c], paginate)

      # `nil` is the signal that there is no such page. Coercing it to a page
      # number makes `next_page` name a page that does not exist, and a client
      # looping on it never terminates.
      assert pagination.next_page == nil
      assert pagination.prev_page == nil
    end

    test "keeps next_page nil on the last page of several" do
      paginate = %{
        current_page: 3,
        current_pages: [1, 2, 3],
        per_page: 1,
        total_count: 3,
        total_pages: 3,
        next_page: nil,
        prev_page: 2
      }

      %TList{pagination: pagination} = TList.new([:c], paginate)

      assert pagination.next_page == nil
      assert pagination.prev_page == 2
    end

    test "keeps prev_page nil on the first page of several" do
      paginate = %{
        current_page: 1,
        current_pages: [1, 2, 3],
        per_page: 1,
        total_count: 3,
        total_pages: 3,
        next_page: 2,
        prev_page: nil
      }

      %TList{pagination: pagination} = TList.new([:a], paginate)

      assert pagination.next_page == 2
      assert pagination.prev_page == nil
    end

    test "passes through both page numbers in the middle of a collection" do
      paginate = %{
        current_page: 2,
        current_pages: [1, 2, 3],
        per_page: 1,
        total_count: 3,
        total_pages: 3,
        next_page: 3,
        prev_page: 1
      }

      %TList{pagination: pagination} = TList.new([:b], paginate)

      assert pagination.next_page == 3
      assert pagination.prev_page == 1
    end

    test "falls back to defaults when the metadata is empty" do
      %TList{pagination: pagination, total: total} = TList.new([], %{})

      assert pagination.current_page == 1
      assert pagination.total_pages == 0
      assert pagination.per_page == 10
      assert pagination.next_page == 0
      assert pagination.prev_page == 1
      assert total == 0
    end
  end
end
