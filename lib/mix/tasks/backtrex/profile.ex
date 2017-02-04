defmodule Mix.Tasks.Backtrex.Profile do
  use Mix.Task

  @shortdoc "Run Backtrex profiler."
  def run(_) do
    output_dir = "profile"
    Backtrex.Profiler.profile(output_dir)
    IO.puts "Profiler data written to #{output_dir}."
  end
end
