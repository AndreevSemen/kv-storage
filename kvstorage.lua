local httpserver = require('http.server')

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
	local ok, json = pcall(request.json, request)
	if (not ok or json['key'] == nil or json['value'] == nil) then
		return BadJSON(request)
	end

	local error = box.space.kv:get(json['key'])
	if (error ~= nil) then
		return FormResponse(request, 409, {error = 'key already exists'})
	end

	box.space.kv:insert({json['key'], json['value']})

	return FormResponse(request, 200, {result = 'record created'})
end

local function Read(request)
	local key = request:stash('id')
	local got = box.space.kv:get(key)
	if (got == nil) then
		return NotFound(request)
	end

	return FormResponse(request, 200, {value = got[2]})
end

local function Update(request)
	local key = request:stash('id')
	local ok, json = pcall(request.json, request)
	if (not ok or json['value'] == nil) then
		return BadJSON(request)
	end

	local updated = box.space.kv:update(key, {{'=', 2, json['value']}})
	if (updated == nil) then
		return NotFound(request)
	end

	return FormResponse(request, 200, {result = 'record updated'})
end

local function Delete(request)
	local key = request:stash('id')
	local deleted = box.space.kv:delete(key)
	if (deleted == nil) then
		return NotFound(request)
	end

	return FormResponse(request, 200, {
		deleted = {
			key = key,
			value = deleted[2]
		}
	})
end


local function RunServer(port)
	local server = httpserver.new('0.0.0.0', os.getenv("PORT"))

	server:route({method = 'POST', path = '/kv'}, Create)
	server:route({method = 'PUT',  path = '/kv/:id'}, Update)
	server:route({method = 'GET',  path = '/kv/:id'}, Read)
	server:route({method = 'DELETE',  path = '/kv/:id'}, Delete)

	server:start()
end


InitTarantool()
RunServer(8080)

