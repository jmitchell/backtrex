defmodule Backtrex.Examples.Sudoku.Solver.Test do
  use ExUnit.Case, async: true

  alias Backtrex.Examples.Sudoku.Puzzle
  alias Backtrex.Examples.Sudoku.Solver

  describe "Solver.solve/1" do
    def example_puzzle do
      {:ok, puzzle} = Puzzle.from_list([
        [5,   3, :_, :_,  7, :_, :_, :_, :_],
        [6,  :_, :_,  1,  9,  5, :_, :_, :_],
        [:_,  9,  8, :_, :_, :_, :_,  6, :_],
        [8,  :_, :_, :_,  6, :_, :_, :_,  3],
        [4,  :_, :_,  8, :_,  3, :_, :_,  1],
        [7,  :_, :_, :_,  2, :_, :_, :_,  6],
        [:_,  6, :_, :_, :_, :_,  2,  8, :_],
        [:_, :_, :_,  4,  1,  9, :_, :_,  5],
        [:_, :_, :_, :_,  8, :_, :_,  7,  9]])
      puzzle
    end

    def expected_solution do
      {:ok, solution} =
        Puzzle.from_list([
          [5, 3, 4, 6, 7, 8, 9, 1, 2],
          [6, 7, 2, 1, 9, 5, 3, 4, 8],
          [1, 9, 8, 3, 4, 2, 5, 6, 7],
          [8, 5, 9, 7, 6, 1, 4, 2, 3],
          [4, 2, 6, 8, 5, 3, 7, 9, 1],
          [7, 1, 3, 9, 2, 4, 8, 5, 6],
          [9, 6, 1, 5, 3, 7, 2, 8, 4],
          [2, 8, 7, 4, 1, 9, 6, 3, 5],
          [3, 4, 5, 2, 8, 6, 1, 7, 9]])
      solution
    end

    test "solve example Sudoku puzzle from Wikipedia article" do
      {:ok, :solution, actual} =
        example_puzzle()
        |> Solver.solve

      assert actual == expected_solution()
    end

    test "discover there's no solution to modified example puzzle" do
      result =
        example_puzzle()
        |> Puzzle.put_cell({1, 1}, 2)
        |> Solver.solve

      assert result == {:ok, :no_solution}
    end
  end
end
