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

  def with_assignments(puzzle, assignments) do
    %Puzzle{
      cells: assignments |> Enum.into(%{}) |> Map.merge(puzzle.cells)
    }
  end

  def valid?(puzzle), do: puzzle |> Puzzle.valid?
end
