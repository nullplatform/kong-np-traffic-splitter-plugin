
FROM kong
COPY np-traffic-splitter /usr/local/share/lua/5.1/kong/plugins/np-traffic-splitter
ENV KONG_PLUGINS bundled,np-traffic-splitter

