return {
  name = "np-traffic-splitter",
  fields = {
    { config = {
        type = "record",
        fields = {
          { traffic_percentage_for_secondary = { type = "number", required = true, between = {0, 100} } },
          { domain = { type = "string", required = true } },
          { disable_np_host = {type="boolean", required = false, default = false}},
          { port = {type="number", required = false, default = 443}},
          { schema = {type="string", required = false, default = "https"}},
          { preserve_host = {type="boolean", required = false, default = true}},
          { upstream = {type="string", required = false}},

        },
      },
    },
  },
}

