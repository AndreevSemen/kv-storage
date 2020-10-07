box.cfg{
	listen = 3301
}

local s
box.once("bootstrap", function()
	s = box.schema.create_space('kv', {format = {
			{name = 'key', type = 'string'},
			{name = 'value', type = '*'},
		},
		if_not_exist = true
	})

	s:create_index('primary', {
		type = 'hash',
		parts = {1, 'string'},
		if_not_exist = true
	})
end)

box.space.kv:insert({0, 'key1', {
		['field key'] = 'filed name',
		['other key'] = {
			'value1',
			'value2'
		}
	}
})

print(box.space.kv:select{'key1'})
