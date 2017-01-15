defmodule Backtrex.Examples.Sudoku.Solver do
  @moduledoc false

  alias Backtrex.Examples.Sudoku.Puzzle
  use Backtrex

  def unknowns(puzzle) do
    puzzle
    |> Puzzle.empty_cells
    |> Enum.to_list
  end

  def values(_puzzle, _cell), do: 1..9

  def assign(puzzle, cell, value) do
    puzzle |> Puzzle.put_cell(cell, value)
  end

  def valid?(puzzle), do: puzzle |> Puzzle.valid?
end
