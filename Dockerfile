FROM tarantool/tarantool:1

ENV PORT=8080
EXPOSE $PORT

COPY ./ /opt/tarantool

ENTRYPOINT ["tarantool", "/opt/tarantool/kvstorage.lua"]
