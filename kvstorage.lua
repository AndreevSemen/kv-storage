local httpserver = require('http.server')
local log        = require('log')


local function InitLog()
	log.usecolor = true
end

local function InitTarantool()
	box.cfg{
		listen = 3301
	}
	box.once("bootstrap", function()
		box.schema.space.create('kv')
		box.space.kv:format{
				{name = 'key', type = 'string'},
				{name = 'value', type = 'map'},
		}
		box.space.kv:create_index('primary', {
			type = 'tree', parts = {1, 'string'}
		})
	end)
end

local function NewLogWrapper(title)
	return function(level, data)
		local color = ""
		if level == 'trace' then
			color = "\27[32m"
		end
		if level == 'info' then
			color = "\27[33m"
		end

		log.info("%s[%s] (%s): %s\27[0m", color, os.date("%H:%M:%S %d/%m/%y"), title, data)
	end
end

local function FormResponse(request, code, json)
	local response = request:render{json = json}
	response.status = code
	return response
end

local function NotFound(request)
	return FormResponse(request, 404, {error = 'key not found'})
end

local function BadJSON(request)
	return FormResponse(request, 400, {error = 'invalid json'})
end


local function Create(request)
	local logger = NewLogWrapper('Create')

	local ok, json = pcall(request.json, request)
	if (not ok or json['key'] == nil or json['value'] == nil) then
		logger('info', 'request with invalid json: '..request.path)
		return BadJSON(request)
	end

	local error = box.space.kv:get(json['key'])
	if (error ~= nil) then
		logger('info', 'creating record with existing key `'..json['key']..'`')
		return FormResponse(request, 409, {error = 'key already exists'})
	end

	box.space.kv:insert({json['key'], json['value']})

	logger('trace', 'record with key `'..json['key']..'` created')
	return FormResponse(request, 200, {result = 'record created'})
end

local function Read(request)
	local logger = NewLogWrapper('Read')

	local key = request:stash('id')
	local got = box.space.kv:get(key)
	if (got == nil) then
		logger('info', 'key `'..key..'` not found')
		return NotFound(request)
	end

	logger('trace', 'record with key `'..key..'` red')
	return FormResponse(request, 200, {value = got[2]})
end

local function Update(request)
	local logger = NewLogWrapper('Create')

	local key = request:stash('id')
	local ok, json = pcall(request.json, request)
	if (not ok or json['value'] == nil) then
		logger('info', 'request with invalid json: '..request.path)
		return BadJSON(request)
	end

	local updated = box.space.kv:update(key, {{'=', 2, json['value']}})
	if (updated == nil) then
		logger('info', 'key `'..key..'` not found')
		return NotFound(request)
	end

	logger('trace', 'record with key `'..key..'` updated')
	return FormResponse(request, 200, {result = 'record updated'})
end

local function Delete(request)
	local logger = NewLogWrapper('Delete')

	local key = request:stash('id')
	local deleted = box.space.kv:delete(key)
	if (deleted == nil) then
		logger('info', 'key `'..key..'` not found')
		return NotFound(request)
	end

	logger('trace', 'record with key `'..key..'` deleted')
	return FormResponse(request, 200, {
		deleted = {
			key = key,
			value = deleted[2]
		}
	})
end


local function RunServer(port)
	local server = httpserver.new('0.0.0.0', os.getenv("PORT"), {
		log_requests = false, -- own logging setted up
		log_errors = true,
		display_errors = false, -- need for storage security
	})

	server:route({method = 'POST', path = '/kv'}, Create)
	server:route({method = 'PUT',  path = '/kv/:id'}, Update)
	server:route({method = 'GET',  path = '/kv/:id'}, Read)
	server:route({method = 'DELETE',  path = '/kv/:id'}, Delete)

	server:start()
end


InitTarantool()
RunServer(8080)

