# Changelog

## Unreleased

### Fixed

- `EctoTurbo.List.new/3` no longer coerces a `nil` `next_page` / `prev_page`
  into a page number. The paginate hook returns `nil` on purpose when there is
  no next (or previous) page, but `List.new/3` used `||`, which cannot tell an
  absent key from a key legitimately holding `nil`. The result was
  `next_page == total_pages` on the last page (and `0` on an empty
  collection) — a page number that does not exist, so a client looping on
  `next_page` never terminated. The default now applies only when the key is
  absent.

  **Behaviour change for consumers:** `pagination.next_page` and
  `pagination.prev_page` are now `null` at the ends of a collection instead of
  being clamped to `total_pages` / `1`. Clients that paginate by comparing
  `current_page` with `total_pages` are unaffected.

- `EctoTurbo.List` gained a test module; the coercion above was uncovered,
  which is why it silently contradicted the assertions in
  `EctoTurbo.turbo/3`'s own tests.

## v0.1.0 (2026-03-26)

Initial release as `ecto_turbo`, a consolidated fork of [turbo_ecto](https://github.com/zven21/turbo_ecto) by Zven Wang.

### Changes from turbo_ecto

- Renamed all modules from `Turbo.Ecto` to `EctoTurbo`
- Fixed `end_with` / `not_end_with` search types (was using `%value%` instead of `%value`)
- Replaced `String.to_atom/1` with `String.to_existing_atom/1` for safer atom conversion
- Added special handling for `"paginate"` key in `symbolize_keys`
- Added `:append` parameter to `OrderBy.build` for ecto_sql 3.11+ compatibility
- Simplified `not_in` syntax to use native `not in` operator
- Updated charlist literals to modern `~c` sigil syntax
- Added sobelow security scanner skip directives
- Changed default `entry_name` from `"datas"` to `"data"` (data is already plural)
- Added `data()` helper function for atom pre-registration
- Bumped minimum Elixir to `~> 1.14`
- Updated dependencies: `ecto_sql ~> 3.11`, `postgrex ~> 0.19`
- Enforced `warnings_as_errors` at compile time
