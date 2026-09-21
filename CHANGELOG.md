# Changelog

## v1.1.0 (2026-09-21)

### Fixed

- Search values are now typed against their column (`type(^value, field(q, ^name))`, `{:array, ...}` for `in` / `not_in`), so Ecto casts and dumps them through the adapter exactly as it does for a hand-written `q.field == ^value`. This fixes `DBConnection.EncodeError` on `Ecto.Enum`, date/time and `:binary_id` (UUID string) columns (#5, #6)
- Struct search values (`%NaiveDateTime{}`, `%Date{}`, `%Decimal{}`, …) are treated as leaf values by the params pre-processing instead of being recursed into, which raised `Protocol.UndefinedError` for `Enumerable` (#6)
- Date/time search values (`:date`, `:time`, `:naive_datetime`, `:utc_datetime` and their `_usec` variants) accept ISO 8601 strings; a date-only value compared against a datetime column is taken as midnight (#6)
- `Ecto.Enum` search values are validated: an invalid value raises an `ArgumentError` listing the allowed values instead of failing later in the adapter. The coercion only applies to comparison search types (`eq`, `not_eq`, `lt`, `lteq`, `gt`, `gteq`, `in`, `not_in`, `between`) (#5)
- `between` bounds are passed as-is instead of being parsed as floats, so integer columns are supported (#6)

### Changed

- Require `ecto_sql ~> 3.12` and drop the pre-3.12 `{:parameterized, mod, params}` type shape (#6)
- Updated locked dependencies to clear security advisories: `decimal` 3.1.1 (GHSA-rhv4-8758-jx7v) and `postgrex` 0.22.4 (GHSA-r73h-97w8-m54h); `ecto` / `ecto_sql` moved to 3.14 (#7)

### Added

- GitHub Actions CI running `mix test` against Postgres 17 and the full `mix audit` alias on every push and pull request (#7)

## v1.0.0 (2026-04-09)

### Added

- `EctoTurbo.List` struct wrapping paginated results with a `Jason.Encoder` implementation; JSON keys are customizable via `:entry_name` and `:paginate_name`, and `per_page` falls back to a default (#3)
- `current_pages` in the pagination payload: the list of page numbers to render, with `"..."` ellipsis markers and at most 9 visible pages (#2)
- Unit tests for every query builder (`LimitOffset`, `OrderBy`, `Join`, `Where`) (#1)
- Development tooling: `credo`, `dialyxir`, `mix_audit`, `doctor`, `sobelow` and a `mix audit` alias running all quality checks

### Changed

- **Breaking:** default `paginate_name` renamed from `"paginate"` to `"pagination"` (#2)
- Minimum Elixir bumped to `~> 1.17`
- All query values are now parameterized (`^value`), which also improves query plan caching (#1)

### Security

- Removed every `Code.eval_quoted/2` call from the query builders. `LimitOffset`, `OrderBy`, `Join` and `Where` now rely exclusively on Ecto's public API (`limit/2`, `offset/2`, `order_by/2`, `join/5`, `dynamic/2`) instead of internal `Ecto.Query.Builder` modules, and `RCE.CodeModule` is no longer ignored by sobelow (#1)

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
