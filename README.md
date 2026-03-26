# EctoTurbo

A rich Ecto component for searching, sorting, and paginating queries.

EctoTurbo is a consolidated fork of [turbo_ecto](https://github.com/zven21/turbo_ecto), with production-tested bug fixes, security improvements, and modern Elixir compatibility.

## Installation

Add `ecto_turbo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_turbo, "~> 0.1.0"}
  ]
end
```

## Configuration

```elixir
# config/config.exs
config :ecto_turbo, EctoTurbo,
  repo: MyApp.Repo,
  per_page: 10,
  entry_name: "datas",
  paginate_name: "paginate"
```

## Usage

### Basic Query with Pagination

```elixir
# Returns %{datas: [...], paginate: %{...}}
EctoTurbo.turbo(Post, %{"page" => 1, "per_page" => 20})
```

### Search

Use the `q` or `filter` parameter to search:

```elixir
# Exact match
EctoTurbo.turbo(Post, %{"q" => %{"price_eq" => 100}})

# Like search
EctoTurbo.turbo(Post, %{"q" => %{"name_like" => "elixir"}})

# Association search
EctoTurbo.turbo(Post, %{"q" => %{"category_name_like" => "tech"}})

# Combined OR search
EctoTurbo.turbo(Post, %{"q" => %{"name_or_body_like" => "elixir"}})
```

#### Supported Search Types

| Type | SQL | Example |
|------|-----|---------|
| `eq` | `col = 'value'` | `price_eq` |
| `not_eq` | `col != 'value'` | `price_not_eq` |
| `lt` | `col < value` | `price_lt` |
| `lteq` | `col <= value` | `price_lteq` |
| `gt` | `col > value` | `price_gt` |
| `gteq` | `col >= value` | `price_gteq` |
| `like` | `col LIKE '%value%'` | `name_like` |
| `not_like` | `col NOT LIKE '%value%'` | `name_not_like` |
| `ilike` | `col ILIKE '%value%'` | `name_ilike` |
| `not_ilike` | `col NOT ILIKE '%value%'` | `name_not_ilike` |
| `in` | `col IN (values)` | `price_in` |
| `not_in` | `col NOT IN (values)` | `price_not_in` |
| `start_with` | `col ILIKE 'value%'` | `name_start_with` |
| `not_start_with` | `col NOT ILIKE 'value%'` | `name_not_start_with` |
| `end_with` | `col ILIKE '%value'` | `name_end_with` |
| `not_end_with` | `col NOT ILIKE '%value'` | `name_not_end_with` |
| `between` | `begin < col AND col < end` | `price_between` |
| `is_true` | `col = true` | `available_is_true` |
| `is_false` | `col = false` | `available_is_false` |
| `is_null` | `col IS NULL` | `name_is_null` |
| `is_present` | `col IS NOT NULL AND col != ''` | `name_is_present` |
| `is_blank` | `col IS NULL OR col = ''` | `name_is_blank` |

### Sort

```elixir
# Single sort
EctoTurbo.turbo(Post, %{"s" => "updated_at+desc"})

# Or using "sort" key
EctoTurbo.turbo(Post, %{"sort" => "price+asc"})

# Multiple sorts
EctoTurbo.turbo(Post, %{"s" => ["updated_at+desc", "name+asc"]})
```

### Options

```elixir
EctoTurbo.turbo(Post, params,
  repo: MyApp.Repo,          # Override configured repo
  per_page: 25,               # Override per_page
  entry_name: "entries",       # Custom key for results
  paginate_name: "meta",       # Custom key for pagination
  with_paginate: false,        # Return flat list without pagination
  prefix: "my_schema",         # Ecto query prefix
  callback: fn q -> q end      # Transform query before execution
)
```

### Query Builder Only

Use `turboq/2` to build the query without executing it:

```elixir
query = EctoTurbo.turboq(Post, %{"q" => %{"name_like" => "elixir"}, "s" => "name+asc"})
# Returns an Ecto.Query struct
```

## Improvements over turbo_ecto

- Safer atom conversion using `String.to_existing_atom/1` to prevent atom table exhaustion
- Fixed `end_with` / `not_end_with` search types (was incorrectly using `%value%` instead of `%value`)
- Compatible with `ecto_sql ~> 3.11` (OrderBy `:append` parameter)
- Modern Elixir syntax (`~c` sigils, `not in` operator)
- Compile-time warnings as errors

## License

MIT - See [LICENSE.md](LICENSE.md) for details.

Originally created by [Zven Wang](https://github.com/zven21).
