defmodule Backtrex.Examples.Sudoku.Puzzle do
  @moduledoc """
  Represents, updates, and verifies Sudoku puzzles.
  """
  alias Backtrex.Examples.Sudoku.Puzzle

  @typedoc "Valid Sudoku row identifiers."
  @type row_id :: 0..8

  @typedoc "Valid Sudoku column identifiers."
  @type column_id :: 0..8

  @typedoc "Valid Sudoku cell identifiers."
  @type cell_id :: {row_id, column_id}

  @typedoc "Values allowed in Sudoku cells."
  @type cell_value :: 1..9 | :_

  @typedoc "`Map` of `cell_id`s to `cell_value`s."
  @type cell_map :: %{optional(cell_id) => cell_value}

  @typedoc "Sudoku puzzle which maps cell IDs to cell values."
  @type puzzle :: %Puzzle{cells: cell_map}

  @doc "`Puzzle` struct that maps cell IDs to cell values."
  defstruct cells: %{}

  @doc """
  Create `Puzzle` from list of lists of cell values.

  ## Examples

  A puzzle copied from
  [Wikipedia](https://en.wikipedia.org/wiki/Sudoku).

      iex> Puzzle.from_list([
      ...> [5,   3, :_, :_,  7, :_, :_, :_, :_],
      ...> [6,  :_, :_,  1,  9,  5, :_, :_, :_],
      ...> [:_,  9,  8, :_, :_, :_, :_,  6, :_],
      ...> [8,  :_, :_, :_,  6, :_, :_, :_,  3],
      ...> [4,  :_, :_,  8, :_,  3, :_, :_,  1],
      ...> [7,  :_, :_, :_,  2, :_, :_, :_,  6],
      ...> [:_,  6, :_, :_, :_, :_,  2,  8, :_],
      ...> [:_, :_, :_,  4,  1,  9, :_, :_,  5],
      ...> [:_, :_, :_, :_,  8, :_, :_,  7,  9],
      ...> ])
      {:ok, %Puzzle{
        cells: %{
          {0, 0} => 5, {0, 1} => 3, {0, 4} => 7,
          {1, 0} => 6, {1, 3} => 1, {1, 4} => 9, {1, 5} => 5,
          {2, 1} => 9, {2, 2} => 8, {2, 7} => 6,
          {3, 0} => 8, {3, 4} => 6, {3, 8} => 3,
          {4, 0} => 4, {4, 3} => 8, {4, 5} => 3, {4, 8} => 1,
          {5, 0} => 7, {5, 4} => 2, {5, 8} => 6,
          {6, 1} => 6, {6, 6} => 2, {6, 7} => 8,
          {7, 3} => 4, {7, 4} => 1, {7, 5} => 9, {7, 8} => 5,
          {8, 4} => 8, {8, 7} => 7, {8, 8} => 9}}}
  """
  @spec from_list([[cell_value]]) :: {:ok, puzzle} | {:error, any()}
  def from_list(rows) when length(rows) == 9 do
    cells =
      rows
      |> Stream.with_index
      |> Stream.map(fn {row, r} ->
        make_row(r, row)
      end)
      |> Enum.reduce(%{}, &Map.merge/2)
    {:ok, %Puzzle{cells: cells}}
  end

  @spec make_row(0..8, [cell_value]) :: cell_map
  defp make_row(r, cell_values) when length(cell_values) == 9 do
    cell_values
    |> Stream.with_index
    |> Stream.filter_map(
    fn {v, _} -> v in 1..9 end,
    fn {val, c} ->
      {{r, c}, val}
    end)
    |> Enum.into(%{})
  end

  @doc "IDs of all cells on a Sudoku grid."
  @spec cell_ids() :: Enum.t
  def cell_ids do
    for r <- 0..8,
        c <- 0..8, do: {r, c}
  end

  @doc """
  9-cell rows, columns, and sectors on the Sudoku grid.

  Each region must have no repeated cell values. See `valid?`.
  """
  @spec regions() :: Enum.t
  @lint {Credo.Check.Refactor.PipeChainStart, false}
         # see https://github.com/rrrene/credo/issues/280
  def regions do
    (for i <- 0..8, do: [row(i), column(i), sector(i)])
    |> Stream.concat()
  end

  @doc """
  Get value of cell at `cell_id` in the `puzzle`.

  Returns `:empty` if no value associated with the `cell_id`.
  """
  @spec cell_value(puzzle, cell_id) :: cell_value
  def cell_value(puzzle, {_r, _c} = cell_id) do
    puzzle.cells |> Map.get(cell_id, :_)
  end

  @doc "Copy of `puzzle` where `cell_value` is associated with `cell_id`."
  @spec put_cell(puzzle, cell_id, cell_value) :: puzzle
  def put_cell(puzzle, cell_id, cell_value) do
    new_cells = puzzle.cells |> Map.put(cell_id, cell_value)
    %Puzzle{puzzle | cells: new_cells}
  end

  @doc """
  Returns whether `puzzle` is valid.

  Each of `puzzle`'s 81 cells must be occupied by a number from 1-9,
  inclusive, or the `:empty` atom. Cells with no value are implictly
  `:empty`.

  Additionally, no individual row, column, nor sector may have repeated
  cell number values. Sectors are the `puzzle`'s nine 3x3 sub-grids.

  ## Examples

      iex> %Puzzle{cells: %{{0, 0} => 1}}
      ...> |> Puzzle.valid?
      true

      iex> %Puzzle{cells: %{{0, 0} => 1, {0, 7} => 1}}
      ...> |> Puzzle.valid?
      false
  """
  @spec valid?(puzzle) :: boolean()
  def valid?(puzzle) do
    regions()
    |> no_counterexample?(&valid_region?(puzzle, &1))
  end

  @spec valid_region?(puzzle, Enum.t) :: boolean()
  defp valid_region?(puzzle, region) do
    region
    |> Stream.map(&(cell_value(puzzle, &1)))
    |> distinct_numbers?
  end

  @doc """
  Returns whether `puzzle` is in a solved state.

  A Sudoku puzzle is said to be solved if it is both `filled_in?` and
  `valid?`.

  ## Examples

      iex> {:ok, puzzle} = Puzzle.from_list([
      ...>   [5, 3, 4, 6, 7, 8, 9, 1, 2],
      ...>   [6, 7, 2, 1, 9, 5, 3, 4, 8],
      ...>   [1, 9, 8, 3, 4, 2, 5, 6, 7],
      ...>   [8, 5, 9, 7, 6, 1, 4, 2, 3],
      ...>   [4, 2, 6, 8, 5, 3, 7, 9, 1],
      ...>   [7, 1, 3, 9, 2, 4, 8, 5, 6],
      ...>   [9, 6, 1, 5, 3, 7, 2, 8, 4],
      ...>   [2, 8, 7, 4, 1, 9, 6, 3, 5],
      ...>   [3, 4, 5, 2, 8, 6, 1, 7, 9]])
      iex> {puzzle |> Puzzle.solved?,
      ...>  puzzle |> Puzzle.put_cell({0, 0}, 1) |> Puzzle.solved?}
      {true, false}
  """
  @spec solved?(puzzle) :: boolean()
  def solved?(puzzle) do
    filled_in?(puzzle) && valid?(puzzle)
  end

  @doc """
  Returns whether `puzzle` has a numerical value in every cell.

  ## Examples

      iex> %Puzzle{cells: %{{0, 0} => 1}}
      ...> |> Puzzle.filled_in?
      false

      iex> %Puzzle{
      ...>   cells: Puzzle.cell_ids
      ...>          |> Enum.map(&({&1, 9}))
      ...>          |> Enum.into(%{})
      ...> } |> Puzzle.filled_in?
      true
  """
  @spec filled_in?(puzzle) :: boolean()
  def filled_in?(puzzle) do
    cell_ids()
    |> no_counterexample?(&(cell_value(puzzle, &1) in 1..9))
  end

  @spec distinct_numbers?(Enum.t) :: boolean()
  defp distinct_numbers?(cell_values) do
    nums =
      cell_values
      |> Stream.filter(&(&1 in 1..9))
      |> Enum.to_list

    (nums |> Enum.count) == (nums |> Stream.uniq |> Enum.count)
  end

  @spec row(row_id) :: [cell_value]
  defp row(r) do
    for c <- 0..8, do: {r, c}
  end

  @spec column(column_id) :: [cell_value]
  defp column(c) do
    for r <- 0..8, do: {r, c}
  end

  @spec sector(0..8) :: [cell_value]
  defp sector(s) do
    {x, y} = {div(s, 3) * 3, rem(s, 3) * 3}
    for r <- y..(y + 2),
        c <- x..(x + 2), do: {r, c}
  end

  @spec no_counterexample?(Enum.t, (any() -> boolean())) :: boolean()
  defp no_counterexample?(enum, pred) do
    enum
    |> Stream.drop_while(pred)
    |> Stream.take(1)
    |> Enum.empty?
  end

  _ = @lint  # see https://github.com/rrrene/credo/issues/291
end
