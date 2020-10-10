FROM tarantool/tarantool:1

EXPOSE 8080

COPY ./ /opt/tarantool

ENTRYPOINT ["tarantool", "/opt/tarantool/kvstorage.lua"]
