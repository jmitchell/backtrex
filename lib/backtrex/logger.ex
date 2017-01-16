defmodule Backtrex.Logger do

  defmacro __using__(_) do
    quote location: :keep do
      require Logger
      import Backtrex.Logger
    end
  end

  defmacro info(msg) do
    quote do
      log(:info, unquote(msg))
    end
  end

  defmacro debug(msg) do
    quote do
      log(:debug, unquote(msg))
    end
  end

  defmacro log(level, chardata_or_fun, metadata \\ []) do
    quote do
      pkg_log_level = :backtrex |> Application.get_all_env |> Keyword.get(:log_level, :warn)
      global_log_level = Logger.level()
      call_logger = fn ->
        macro =
          case unquote(level) do
            :info -> &Logger.info/2
            :debug -> &Logger.debug/2
          end
        macro.(unquote(chardata_or_fun), unquote(metadata))
      end
      case Logger.compare_levels(pkg_log_level, global_log_level) do
        :lt ->
          Logger.configure(level: pkg_log_level)
          call_logger.()
          Logger.configure(level: global_log_level)
        _ ->
          call_logger.()
      end
    end
  end


end
