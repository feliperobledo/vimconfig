-- Initialize options before lazy loading packages
require("config.options")
require('config.lazy')

-- Load core config in a deterministic order
require("config.keymaps")
require("config.commands")
