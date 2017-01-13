defmodule Backtrex do
  @moduledoc """
  A [backtracking](https://en.wikipedia.org/wiki/Backtracking)
  behaviour for solving discrete computational problems.
  """

  import Logger

  @typedoc """
  A puzzle with a set of `unknown`s, possible `assignment`s
  for each, and an invariant property.

  Each type of `problem` must have ways to:

  1. enumerate its unknowns (see `c:unknowns`),
  2. enumerate `value`s that could be assigned to any particular
  `unknown` in a solution (see `c:values`).
  3. incorporate proposed `assignments` (see `c:with_assignments`),
  and
  4. check whether the invariant holds (see `c:valid?`).
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
  Next value to try.
  """
  @type maybe_value :: {:ok, value} | :none

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

  @callback unknowns(problem) :: [unknown]
  @callback values(problem, unknown) :: Enum.t # of `value`
  @callback with_assignments(problem, [assignment]) :: problem
  @callback valid?(problem) :: boolean()

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Backtrex

      @spec solve(Backtrex.problem) :: Backtrex.result
      def solve(problem) do
        info fn -> "Attempting to solve problem #{inspect problem, pretty: true, charlists: :as_list}" end
        search(problem, unknowns(problem), [])
      end

      @spec search(
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment_search])
      :: Backtrex.result
      defp search(problem, unknowns, assignments) do
        new_problem = problem |> do_with_assignments(assignments)
        debug fn -> """
        search/3:

          problem: #{inspect problem, pretty: true, charlists: :as_list}
          unknowns: #{inspect unknowns, pretty: true, charlists: :as_list}
          assignments: #{inspect assignments, pretty: true, charlists: :as_list}
          problem w/ assignments: #{inspect new_problem, pretty: true, charlists: :as_list}
        """ end
        if new_problem |> valid? do
          search_valid(problem, new_problem, unknowns, assignments)
        else
          search_invalid(problem, unknowns, assignments)
        end
      end

      @spec do_with_assignments(
        Backtrex.problem,
        [Backtrex.assignment_search])
      :: [Backtrex.assignment]
      defp do_with_assignments(problem, assignments) do
        curr_assignments =
          assignments
          |> Stream.map(fn {uv, _vs} -> uv end)
          |> Enum.to_list

        with_assignments(problem, curr_assignments)
      end

      # TODO: Consider using a stack of problems instead of
      # `original_problem` and `new_problem`. May simplify code AND
      # reduce `do_with_assignments/2` as a potential bottleneck
      # (profile first, though).
      @spec search_valid(
        Backtrex.problem,
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment_search])
      :: Backtrex.result
      defp search_valid(original_problem, new_problem, unknowns, assignments) do
        debug "search_valid/3"
        case new_problem |> unknowns do
          [] ->
            info "Problem solved!"
            {:ok, :solution, new_problem}
          [u | us] ->
            case new_problem |> values(u) |> split do
              {[curr_value], additional_values} ->
                debug fn -> "search/3: continuing search with #{inspect curr_value} assigned to unknown #{inspect u}, and additional values to try: #{inspect additional_values, charlists: :as_list}" end
                search(original_problem, us, [{{u, curr_value}, additional_values} | assignments])
              {[], _} ->
                {:ok, :no_solution}
            end
        end
      end

      @spec search_invalid(
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment_search])
      :: Backtrex.result
      defp search_invalid(problem, unknowns, assignments) do
        debug "search_invalid/3"
        case assignments do
          [] ->
            info "No solution: invalid problem"
            {:ok, :no_solution}
          [{{curr_unk, _curr_val}, additional_vals} | prev_as] ->
            case additional_vals |> split do
              {[new_val], vals} ->
                debug fn -> "search/3: trying next value, #{inspect new_val}, for unknown #{inspect curr_unk}. Additional values to try: #{inspect vals, charlists: :as_list}." end
                search(problem, unknowns, [{{curr_unk, new_val}, vals} | prev_as])
              {[], _} ->
                backtrack(problem, [curr_unk, unknowns], prev_as)
            end
        end
      end

      @spec split(Enum.t) :: {[any()], Enum.t}
      @spec split(Enum.t, non_neg_integer()) :: {[any()], Enum.t}
      defp split(stream, count \\ 1) when count >= 0 do
        # Probably a more efficient way to do this. See
        # https://elixirforum.com/t/enum-split-2-which-does-not-force-the-tail-of-a-stream/1900/8
        # and https://github.com/tallakt/stream_split
        {stream |> Stream.take(count) |> Enum.to_list,
         stream |> Stream.drop(count)}
      end

      @spec backtrack(
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment_search])
      :: Backtrex.result
      defp backtrack(problem, unknowns, [{{u, _old_v}, values} | assignments]) do
        case values |> split(1) do
          {[], _} ->
            backtrack(problem, [u | unknowns], assignments)
          {[new_v], vs} ->
            search(problem, unknowns, [{{u, new_v}, vs} | assignments])
        end
      end
      defp backtrack(_problem, _unknowns, []), do: {:ok, :no_solution}

    end
  end
end
