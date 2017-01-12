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

  def with_assignments(puzzle, []), do: puzzle
  def with_assignments(puzzle, [{cell_id, value} | assignments]) do
    puzzle
    |> Puzzle.put_cell(cell_id, value)
    |> with_assignments(assignments)
  end
  def with_assignments(_puzzle, assignments) do
    {:error,
     "with_assignments/2: unexpected assignments, #{inspect assignments}"}
  end

  def valid?(puzzle), do: puzzle |> Puzzle.valid?
end
