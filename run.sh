docker build . -t nkong
docker run --name kong --rm \
    -e "KONG_DATABASE=off" \
    -e KONG_LOG_LEVEL=debug \
    -e "KONG_DECLARATIVE_CONFIG=/etc/kong/kong.yml" \
    -v "$(pwd)/kong.yml:/etc/kong/kong.yml" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 8444:8444 \
    nkong
