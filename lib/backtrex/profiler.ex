defmodule Backtrex.Profiler do
  alias Backtrex.Examples.Sudoku

  def eflame do
    :eflame.apply(&run_test/0, [])
  end

  def fprof do
    :fprof.apply(&run_test/0, [])
    :fprof.profile()
    :fprof.analyse([
      callers: true,
      sort: :own,
      totals: true,
      details: true])
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

  def run_test do
    {:ok, :solution, _} = example_puzzle() |> Sudoku.Solver.solve
  end
end
