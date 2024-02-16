# lua-resty-planetscale

Lua PlanetScale driver library for use in context of [ngx_lua](https://github.com/openresty/lua-nginx-module) or [OpenResty](ngx_luahttp://openresty.org/) to execute database queries over http(s).

## Status

> :warning: Work In-Progress (Active Development)
>
> Not for use in production. Features and interface are experimental and not stable.

## Development Status

| :vertical_traffic_light: | Task                                                                       |
| ------------------------ | -------------------------------------------------------------------------- |
| :white_check_mark:       | Initial commit.                                                            |
| :small_orange_diamond:   | Local development setup.                                                   |
| :x:                      | Support connection by DATABASE_URL.                                        |
| :x:                      | Create db connections and sessions.                                        |
| :x:                      | Execute a standalone db query.                                             |
| :x:                      | Support connection by DATABASE_HOST, DATABASE_USER, and DATABASE_PASSWORD. |
| :x:                      | Support db transactions.                                                   |
| :x:                      | Add `nginx::test` unit testing (the `/t` directory).                       |
| :x:                      | Optimize or pool objects.                                                  |
| :x:                      | Remove optional dependencies.                                              |

## Quickstart

A basic example.

```lua
local planetscale = require('resty.planetscale')
local db = planetscale.new({
  url = 'mysql://username:password@host.com/example'
})
local result = db:execute('SELECT version();')
```

## Reference

### planetscale.new

`planetscale.new(config)`

Create a new PlanetScale db client.

Configuration must be supplied either by providing:

- a connection `url` (this is commonly called `DATABASE_URL` in your PlanetScale Concole), _or_
- a combination of `host`, `username`, and `password`.

#### Connection `url` Example

```lua
local db = planetscale.new({
  url = 'mysql://username:password@host.com/example'
})
```

In practice, in the context of nginx, this may look like:

```lua
local db = planetscale.new({
  url = os.getenv('DATABASE_URL'),
})
```

#### Connection `host`, `username`, and `passsword` Example

> :warning: TODO: implement

```lua
local db = planetscale.new({
  host = 'host.com',
  username = 'username',
  password = 'password',
})
```

In practice, in the context of nginx, this may look like:

```lua
local db = planetscale.new({
  host = os.getenv('DATABASE_HOST"),
  username = os.getenv('DATABASE_USERNAME'),
  password = os.getenv('DATABASE_PASSWORD'),
})
```

### db:execute

> :warning: TODO: document

### db:refresh

> :warning: TODO: document

## CONTRIBUTING

To contribute, check out the [CONTRIBUTING](./CONTRIBUTING.md) guide.
