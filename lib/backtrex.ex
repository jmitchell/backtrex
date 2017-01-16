defmodule Backtrex do
  @moduledoc """
  A [backtracking](https://en.wikipedia.org/wiki/Backtracking)
  behaviour for solving discrete computational problems.
  """

  use Backtrex.Logger

  @typedoc """
  A puzzle with a set of `unknown`s, possible `assignment`s
  for each, and an invariant property.

  Each type of `problem` must have ways to:

  1. enumerate its unknowns (see `c:Backtrex.unknowns/1`),
  2. enumerate `value`s that could be assigned to any particular
  `unknown` in a solution (see `c:Backtrex.values/2`).
  3. incorporate proposed assignments of `value`s to `unknown`s (see
  `c:Backtrex.assign/3`), and
  4. check whether the invariant holds (see `c:Backtrex.valid?/1`).
  """
  @type problem :: any()

  @typedoc """
  Unique identifier for an unknown in a `problem`.
  """
  @type unknown :: any()

  @typedoc """
  Value that could be assigned to an `unknown`.
  """
  @type value :: any()

  @typedoc """
  Potential `value` assignment for some `unknown`.
  """
  @type assignment :: {unknown, value}

  @typedoc """
  An `assignment` with a list of `value`s left to try.
  """
  @type assignment_search :: {assignment, [value]}

  @type result :: {:ok, :solution, problem}
                | {:ok, :no_solution}

  @doc """
  Open questions in `problem` that a solution must answer.

  In Sudoku this would be the puzzle's blank cells.
  """
  @callback unknowns(problem) :: [unknown]

  @doc """
  Potential answers to an `unknown` in the context of a `problem`.

  Every cell in Sudoku, for instance, must be a number between 1 and 9,
  inclusive, so a Sudoku solver would return `1..9`. In this case the result
  doesn't depend on `puzzle` or `unknown`, but for other problems it might.
  """
  @callback values(problem, unknown) :: Enum.t # of `value`

  @doc """
  Updated `problem` with `value` assigned to `unknown`.

  Assignments may be wrong in the sense that they will not lead to a solution.
  Backtrex maintains a copy of the original problem, and uses the
  `c:Backtrex.valid?/1` callback to ensure assignments are productive.
  """
  @callback assign(problem, unknown, value) :: problem

  @doc """
  Return whether `problem` is in a valid state.

  An invalid state means there's no way to solve `problem` in its current state.
  This callback determines whether to march forward, tackling new unknowns, or
  backtrack, rewriting the provisional answers that led to this state.
  """
  @callback valid?(problem) :: boolean()

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Backtrex

      def solve(problem) do
        Backtrex.solve(__MODULE__, problem)
      end
    end
  end

  @spec solve(module, problem) :: result
  def solve(module, problem) do
    info fn -> "Attempting to solve problem #{inspect problem, pretty: true}" end
    unknowns = apply(module, :unknowns, [problem]) |> Enum.to_list
    search(module, problem, unknowns, [])
  end

  @spec search(
    module,
    problem,
    [unknown],
    [assignment_search])
  :: result
  def search(module, problem, unknowns, assignments) do
    new_problem =
      assignments
      |> Stream.map(fn {uv, _vs} -> uv end)
      |> Enum.reduce(problem, fn({unknown, value}, prob) ->
        apply(module, :assign, [prob, unknown, value])
      end)
      debug fn -> """
      search/3:

      problem: #{inspect problem, pretty: true, charlists: :as_list}
      unknowns: #{inspect unknowns, pretty: true, charlists: :as_list}
      assignments: #{inspect assignments, pretty: true, charlists: :as_list}
      problem w/ assignments: #{inspect new_problem, pretty: true, charlists: :as_list}
      """ end
      if apply(module, :valid?, [new_problem]) do
        search_valid(module, problem, new_problem, unknowns, assignments)
      else
        search_invalid(module, problem, unknowns, assignments)
      end
  end

  # TODO: Consider using a stack of problems instead of
  # `original_problem` and `new_problem`. May simplify code AND
  # reduce `do_with_assignments/2` as a potential bottleneck
  # (profile first, though).

  @spec search_valid(
    module,
    problem,
    problem,
    [unknown],
    [assignment_search])
  :: result
  defp search_valid(module, original_problem, new_problem, _unknowns, assignments) do
    debug "search_valid/3"
    case apply(module, :unknowns, [new_problem]) |> Enum.to_list do
      [] ->
        info "Problem solved!"
        {:ok, :solution, new_problem}
      [u | us] ->
        case apply(module, :values, [new_problem, u]) |> split do
          {[curr_value], additional_values} ->
            debug fn -> "search/3: continuing search with #{inspect curr_value} assigned to unknown #{inspect u}, and additional values to try: #{inspect additional_values, charlists: :as_list}" end
            search(module, original_problem, us, [{{u, curr_value}, additional_values} | assignments])
          {[], _} ->
            {:ok, :no_solution}
        end
    end
  end

  @spec search_invalid(
    module,
    problem,
    [unknown],
    [assignment_search])
  :: result
  defp search_invalid(module, problem, unknowns, assignments) do
    debug "search_invalid/3"
    case assignments do
      [] ->
        info "No solution: invalid problem"
        {:ok, :no_solution}
      [{{curr_unk, _curr_val}, additional_vals} | prev_as] ->
        case additional_vals |> split do
          {[new_val], vals} ->
            debug fn -> "search/3: trying next value, #{inspect new_val}, for unknown #{inspect curr_unk}. Additional values to try: #{inspect vals, charlists: :as_list}." end
            search(module, problem, unknowns, [{{curr_unk, new_val}, vals} | prev_as])
          {[], _} ->
            backtrack(module, problem, [curr_unk, unknowns], prev_as)
        end
    end
  end

  @spec backtrack(
    module,
    problem,
    [unknown],
    [assignment_search])
  :: result
  defp backtrack(module, problem, unknowns, [{{u, _old_v}, values} | assignments]) do
    case values |> split(1) do
      {[], _} ->
        backtrack(module, problem, [u | unknowns], assignments)
      {[new_v], vs} ->
        search(module, problem, unknowns, [{{u, new_v}, vs} | assignments])
    end
  end
  defp backtrack(_module, _problem, _unknowns, []), do: {:ok, :no_solution}

  @spec split(Enum.t) :: {[any()], Enum.t}
  @spec split(Enum.t, non_neg_integer()) :: {[any()], Enum.t}
  defp split(stream, count \\ 1) when count >= 0 do
    # Probably a more efficient way to do this. See
    # https://elixirforum.com/t/enum-split-2-which-does-not-force-the-tail-of-a-stream/1900/8
    # and https://github.com/tallakt/stream_split
    {stream |> Stream.take(count) |> Enum.to_list,
     stream |> Stream.drop(count)}
  end

end
