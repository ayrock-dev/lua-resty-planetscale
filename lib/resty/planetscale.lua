-- luacheck: globals ngx

local httpc = require("resty.http").new()
local resty_url = require("resty.url")
local cjson = require("cjson")

--- Make a POST request with a json body
--
-- @param config (table)
-- @field user (string)
-- @field password (string)
--
-- @param url (string) The URL to make the request to
--
-- @param body (table) The response body
local function post_json(config, url, body)
	body = body or {}
	local auth = "Basic " .. ngx.encode_base64(config.user .. ":" .. config.password)

	ngx.log(ngx.DEBUG, "making a request to: ", url)
	ngx.log(ngx.DEBUG, "with body: ", cjson.encode(body))

	local res, err = httpc:request_uri(url, {
		method = "POST",
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = auth,
		},
		cache = "no-store",
		body = cjson.encode(body),
		ssl_verify = false, -- TODO: consider
	})

	if err or res == nil then
		ngx.log(ngx.ERR, "request failed: ", cjson.encode({ err, res }))
		return
	end

	ngx.log(ngx.DEBUG, "response status: ", res.status)

	if res.status ~= 200 then
		ngx.log(ngx.ERR, "failed to create session: ", res.status, " ", res.reason)
		return
	end

	return cjson.decode(res.body)
end

local function cast(field, value)
	if not value then
		return value
	end

	if
		field.type == "INT8"
		or field.type == "INT16"
		or field.type == "INT24"
		or field.type == "INT32"
		or field.type == "UINT8"
		or field.type == "UINT16"
		or field.type == "UINT24"
		or field.type == "UINT32"
		or field.type == "YEAR"
		or field.type == "FLOAT32"
		or field.type == "FLOAT64"
	then
		return tonumber(value)
	elseif
		field.type == "DECIMAL"
		or field.type == "INT64"
		or field.type == "UINT64"
		or field.type == "DATE"
		or field.type == "TIME"
		or field.type == "DATETIME"
		or field.type == "TIMESTAMP"
	then
		return value
	elseif field.type == "BLOB" or field.type == "BIT" or field.type == "GEOMETRY" then
		return value -- todo
	elseif field.type == "BINARY" or field.type == "VARBINARY" then
		return value -- todo
	elseif field.type == "JSON" then
		return value and cjson.decode(value) or value
	else
		return value -- todo
	end
end

local function decode_row(row)
	local values = row.values and ngx.decode_base64(row.values) or ""
	local offset = 0
	local decoded = {}
	for i, size in ipairs(row.lengths) do
		local width = tonumber(size)
		if width == 0 then
			table.insert(decoded, nil)
		else
			local value = values:sub(offset, offset + width)
			table.insert(decoded, value)
			offset = offset + width
		end
	end
	return decoded
end

local function parse_row(fields, row)
	ngx.log(ngx.DEBUG, "parsing row: ", cjson.encode({ fields, row }))

	local decoded_row = decode_row(row)
	local parsed = {}
	for i, field in ipairs(fields) do
		local value = decoded_row[i]
		parsed[field.name] = cast(field, value)
	end
	return parsed
end

local function parse(result)
	local fields = result.fields or {}
	local rows = result.rows or {}
	local parsed = {}
	for i, row in ipairs(rows) do
		local parsed_row = parse_row(fields, row)
		table.insert(parsed, parsed_row)
	end
	return parsed
end

--- @class Connection
local Connection = {
	config = nil,
	session = nil,
	base_url = nil,
}
Connection.__index = Connection

--- Create a new PlanetScale connection
--
-- @param config
-- @field url (string) A database connection string. This can be obtained from the PlanetScale Console.
--
-- @return Connection
function Connection.new(config)
	local inst = {
		config = config,
		session = nil,
		base_url = nil,
	}

	if config and config.url then
		local url = resty_url.parse(config.url)
		inst.config.user = url.user
		inst.config.password = url.password
		inst.config.host = url.host
		inst.base_url = "https://" .. url.host
	end

	return setmetatable(inst, Connection)
end

--- Execute a query
--
-- @param query (string) A SQL query to execute
--
-- @return A PlanetScale query result object
function Connection:execute(query)
	local url = self.base_url .. "/psdb.v1alpha1.Database/Execute"

	-- todo: escape and sanitize query
	local sql = query

	local saved = post_json(self.config, url, {
		query = sql,
		session = self.session,
	})

	if saved and saved.session then
		self.session = saved.session
	end

	if saved and saved.error then
		ngx.log(ngx.ERR, "query executed with error: ", saved.error.message)
		return
	end

	local rows_affected = saved
			and saved.result
			and saved.result["rowsAffected"]
			and tonumber(saved.result["rowsAffected"])
		or 0
	local insert_id = saved and saved.result and saved.result["insertId"] or "0"

	local fields = saved and saved.result and saved.result.fields or {}
	for i, _ in ipairs(fields) do
		fields[i] = fields[i] or "NULL"
	end
	local headers = {}
	for i, field in ipairs(fields) do
		table.insert(headers, field.name)
	end

	local rows = saved and saved.result and parse(saved.result) or {}

	local timing_seconds = saved and saved.timing or 0

	return {
		headers = headers,
		fields = fields,
		rows = rows,
		rows_affected = rows_affected,
		insert_id = insert_id,
		size = #rows,
		statement = sql,
		timing_millis = timing_seconds * 1000,
	}
end

function Connection:refresh()
	self:create_session()
end

--- Get a PlanetScale session
--
-- @return A Planetscale session
function Connection:create_session()
	local url = self.base_url .. "/psdb.v1alpha1.Database/CreateSession"
	local result = post_json(self.config, url)
	local session = result and result.session or nil
	self.session = session
	return session
end

--- @class Client
local Client = {
	config = nil,
}
Client.__index = Client

--- Create a new PlanetScale client
--
-- @param config
-- @field url Database connection string. This can be obtained from the PlanetScale Console.
--
-- @return Client
function Client.new(config)
	return setmetatable({ config = config }, Client)
end

--- Execute a query against the database
--
-- @param query A SQL query to execute
function Client:execute(query)
	return self:connection():execute(query)
end

--- Create a new connection to the database
--
-- @return Connection
function Client:connection()
	return Connection.new(self.config)
end

return Client
