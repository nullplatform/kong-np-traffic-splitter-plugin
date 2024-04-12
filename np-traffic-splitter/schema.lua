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
          { use_cookies = {
            type= "record",
            required = false,
            fields = {
              {
                enabled = {
                  type = "boolean",
                  required = false,
                  default = false
                }
              },
              {
                max_age = {
                  type = "number",
                  required = false,
                  default = 300
                }
              },
              {
                path = {
                  type = "string",
                  required = false
                }
              },
              {
                secure = {
                  type = "boolean",
                  required = false
                }
              },
              {
                http_only = {
                  type = "boolean",
                  required = false,
                }
              },
              {
                same_site = {
                  type = "string",
                  required = false,
                  one_of = {
                    "Strict",
                    "Lax",
                    "None"
                  }
                }
              },
            }
          }},

        },
      },
    },
  },
}

