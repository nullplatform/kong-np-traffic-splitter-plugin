# NP-Traffic-Splitter

The NP-Traffic-Splitter plugin enables dynamic traffic routing, allowing a percentage of traffic to be directed to an alternate destination, even if it uses a different protocol. This plugin also introduces the `x-np-host` header, facilitating the routing of traffic to NullPlatform while preserving the original host.


## How to install it

```bash
# Copy the np-traffic-splitter folder to Kong's plugin directory
cp -r np-traffic-splitter /usr/local/share/lua/5.1/kong/plugins/

# Update your environment variables to include np-traffic-splitter
export KONG_PLUGINS=bundled,np-traffic-splitter
```

## How to use it

To use the NP-Traffic-Splitter plugin, define it in your Kong route configuration like this:

```
_format_version: "2.1"
      
services:
  - name: my-service
    url: original-url
    routes:
      - name: my-route
        paths:
          - /test
    plugins:
      - name: np-traffic-splitter
        config:
          traffic_percentage_for_secondary: 30
          domain: test-url
```

### Extra options

Customize the plugin behavior with these additional options:

- disable_np_host: Boolean, default false. If true, the x-np-host header is not added.
- port: Specifies the port to use, default is 443.
- schema: Defines the protocol schema, default is https.
- preserve_host: Boolean, default true. If false, the original host is not forwarded to the target.
- upstream: if old versions (prev 3.6) hostnames can't be used as targets inside the plugin so a new upstream should be defined and set with the upstream key

## Running the example

To run the provided example:

```bash
./run.sh
```

This script starts a Kong server on port 8000 with the NP-Traffic-Splitter plugin activated. You can edit kong.yml to experiment with the configuration.


## Running tests

To execute the test suite:

```bash
# Inside the np-traffic-splitter directory
./run_tests.sh

# Or run tests directly with lua
busted handler_spec.lua

```

