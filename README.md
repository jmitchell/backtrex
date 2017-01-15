# Backtrex [![Build Status](https://travis-ci.org/jmitchell/backtrex.svg?branch=master)](https://travis-ci.org/jmitchell/backtrex)

Logic puzzles and similar problems can be solved by exploring the
space of possible solutions. By enumerating potential answers to open
questions like "what should go in this cell?" or "which direction
should I go now?", checking whether a given set of those answers is
valid, and revising answers whenever you reach an invalid state you'll
eventually find the solution (assuming one exists and the problem is
finite). This strategy is known
as [backtracking](https://en.wikipedia.org/wiki/Backtracking) and has
a surprising range of applications. A few simple callbacks are all
Backtrex needs to get to work.

## Getting Started

Backtrex is an Elixir project, and these directions assume you are
using the `mix` tool. However, it should be possible to use this
project in Erlang as well.

### Installing

Add `backtrex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:backtrex, "~> 0.1.1"}]
end
```

Then run `mix do deps.get`.

Backtrex currently makes a lot of Logger.debug calls. To avoid seeing
them, add the following to `config/config.exs`:

```elixir
config :logger, level: :warn
```

### Usage

Suppose you want to make a Sudoku solver, and you already have ways to
represent, update, and validate puzzles. Here's roughly what the
solver, a Backtrex behaviour, would look like:

```elixir
defmodule SudokuSolver do
  use Backtrex
  
  def unknowns(puzzle) do
    puzzle |> SudokuPuzzle.empty_cells
  end
  
  def values(_puzzle, _cell), do: 1..9
  
  def assign(puzzle, cell, value) do
    puzzle |> SudokuPuzzle.put_cell(cell, value)
  end

  def valid?(puzzle), do: puzzle |> SudokuPuzzle.valid?
end
```

In return for implementing these callbacks, Backtrex gives you a
`SudokuSolver.solve/1` function for free.

The documentation
at [https://hexdocs.pm/backtrex](https://hexdocs.pm/backtrex) explains
what Backtrex expects from these callbacks.

Similar Sudoku solver code is available
in
[`lib/examples/sudoku`](https://github.com/jmitchell/backtrex/tree/master/lib/examples/sudoku). For
now those modules are even shipped with the package. Try it out in
your project:

```elixir
defmodule Sandbox do
  alias Backtrex.Examples.Sudoku.Puzzle
  alias Backtrex.Examples.Sudoku.Solver

  def hello_backtrex do
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

    {:ok, expected_solution} = Puzzle.from_list([
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9]])

    {:ok, :solution, solution} = puzzle |> Solver.solve

    solution == expected_solution
  end
end
```

`Sandbox.hello_backtrex/0` should return true within 5 seconds or
so.

## Other applications

Sudoku makes for a good introductory demo, but it doesn't showcase the
flexibility of Backtrex's design. Here's some other applications I
suspect it could handle.

- incomplete information
  - corn maze of unknown size; visibility limited to what's nearby.
- don't know until you get there
  - finding a string of 5 characters that hashes to a certain value.
- programming language features
  - pattern matching engine
  - type checker

## License

Backtrex is licensed under Apache 2.0. See
the
[LICENSE file](https://github.com/jmitchell/backtrex/blob/master/LICENSE).
