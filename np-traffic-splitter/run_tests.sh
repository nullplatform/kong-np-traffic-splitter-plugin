#!/bin/bash

if [ -f /var/run/docker.sock ]; then
    sudo docker build . 
    BUILD_STATUS=$?
    if [ $BUILD_STATUS -ne 0 ]; then
        echo "Tests failed"
    fi
    exit $BUILD_STATUS
fi

which busted

if [ $? -ne 0 ]; then
    echo "You should have installed busted, to install it run 'luarocks install busted'"
    exit 1;
fi

busted handler_spec.lua 