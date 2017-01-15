defmodule Backtrex.Examples.Sudoku.Solver do
  @moduledoc false

  use Backtrex

  alias Backtrex.Examples.Sudoku.Puzzle

  def unknowns(puzzle) do
    Puzzle.empty_cells(puzzle)
  end

  def values(_puzzle, _cell), do: 1..9

  def assign(puzzle, cell, value) do
    Puzzle.put_cell(puzzle, cell, value)
  end

  def valid?(puzzle) do
    Puzzle.valid?(puzzle)
  end
end
