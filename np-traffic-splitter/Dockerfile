FROM kong:3.3.1-alpine 

WORKDIR /test
USER root

# Install LuaRocks and Busted for Lua testing
RUN apk update && \
    apk add --no-cache build-base && \
    apk add --no-cache luajit-dev lua5.1-lpeg lua5.1-socket && \
    luarocks install busted
# Copy the plugin and test files into the container
COPY handler.lua /test
COPY schema.lua /test
COPY handler_spec.lua /test
USER kong
# Run the tests when the container launches
RUN busted handler_spec.lua