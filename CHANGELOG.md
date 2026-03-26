# Changelog

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
- Added `datas()` helper function for atom pre-registration
- Bumped minimum Elixir to `~> 1.14`
- Updated dependencies: `ecto_sql ~> 3.11`, `postgrex ~> 0.19`
- Enforced `warnings_as_errors` at compile time
