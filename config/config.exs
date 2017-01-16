use Mix.Config

config :backtrex,
  # Overrides `Logger`'s `:level` in `Backtrex`'s modules, but may be overridden
  # by `:compile_time_purge_level`.
  log_level: :warn

config :logger,
  compile_time_purge_level: :warn

import_config "#{Mix.env}.exs"
