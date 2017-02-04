defmodule Backtrex.Profiler do
  alias Backtrex.Examples.Sudoku

  @spec backends() :: [atom()]
  def backends do
    [
      :naive_sequential,
    ]
  end

  @spec problems() :: [{module(), [{atom(), any()}]}]
  def problems do
    [
      {Sudoku.Solver,
       [
         quick_puzzle: example_puzzle()
       ]},
    ]
  end

  def combos do
    for backend <- backends(),
        {frontend, inputs} <- problems() do
      for input <- inputs, do: {backend, frontend, input}
    end
    |> Enum.concat()
  end

  def combo_name({b, f, {n, _}}) do
    "#{inspect b}-#{inspect f}-#{inspect n}"
    |> String.replace(":", "")
  end

  def profile(dir \\ "./profile") do
    if !File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    eflame(dir)
    fprof(dir)
  end

  def eflame(dir) do
    combos()
    |> Enum.each(fn combo ->
      fname = Path.join(dir, "stacks-#{combo_name(combo)}.out")
      :eflame.apply(:normal_with_children, fname, __MODULE__, :run_test, [combo])
      System.cmd("bash", ["./script/make_flamegraph.sh", fname])
    end)
  end

  def fprof(dir) do
    combos()
    |> Enum.each(fn combo ->
      trace_file = Path.join(dir, "fprof-#{combo_name(combo)}.trace") |> to_charlist
      analysis_file = Path.join(dir, "fprof-#{combo_name(combo)}.analysis") |> to_charlist
      :fprof.apply(&run_test/1, [combo], [
                     {:file, trace_file}
                   ])
      :fprof.profile(file: trace_file)
      :fprof.analyse([
        dest: analysis_file,
        callers: true,
        sort: :own,
        totals: true,
        details: true])
    end)
  end

  def example_puzzle do
    {:ok, puzzle} = Sudoku.Puzzle.from_list([
      [5,   3, :_, :_,  7, :_, :_,  1,  2],
      [6,   7, :_,  1,  9,  5, :_,  4, :_],
      [1,   9,  8,  3, :_, :_,  5,  6,  7],
      [8,  :_,  9, :_,  6, :_,  4, :_,  3],
      [4,   2, :_,  8, :_,  3,  7, :_,  1],
      [7,  :_,  3, :_,  2,  4, :_,  5,  6],
      [:_,  6, :_,  5, :_,  7,  2,  8, :_],
      [2,  :_, :_,  4,  1,  9,  6, :_,  5],
      [:_,  4,  5, :_,  8,  6, :_,  7,  9]])
    puzzle
  end

  def run_test({backend, frontend, {_name, input}}) do
    {:ok, :solution, _} = apply(frontend, :solve, [input, backend])
  end

  def run_test do
    example_puzzle() |> Backtrex.Examples.Sudoku.Solver.solve
  end
end
