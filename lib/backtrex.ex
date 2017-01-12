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

      @spec solved?(Backtrex.problem) :: boolean()
      def solved?(problem) do
        valid?(problem) && Enum.empty?(unknowns(problem))
      end

      @spec solve(Backtrex.problem) :: Backtrex.result
      def solve(problem) do
        info "Attempting to solve problem #{inspect problem, pretty: true, charlists: :as_list}"
        search(problem, unknowns(problem), [])
      end

      @spec search(
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment])
      :: Backtrex.result
      def search(problem, [], []) do
        if problem |> solved? do
          {:ok, :solution, problem}
        else
          {:ok, :no_solution}
        end
      end
      def search(problem, [unknown | us], []) do
        if problem |> solved? do
          info "Problem solved!"
          {:ok, :solution, problem}
        else
          case problem |> values(unknown) |> Enum.to_list do
            [curr_value | additional_values] ->
              search(problem, us, [{{unknown, curr_value}, additional_values}])
            x ->
              {:error,
               "search/3: unexpected response from `values/2` callback: #{inspect x}"}
          end
        end
      end
      def search(problem, unknowns, assignments) do
        new_problem =
          problem
          |> with_assignments(assignments |> Enum.map(fn {{u, v}, _vs} -> {u, v} end))
        debug """
        search/3:

          problem: #{inspect problem, pretty: true, charlists: :as_list}
          assignments: #{inspect assignments, pretty: true, charlists: :as_list}
          problem w/ assignments: #{inspect new_problem, pretty: true, charlists: :as_list}
        """
        if new_problem |> valid? do
          debug "search/3: problem with assignments is valid."
          case new_problem |> unknowns do
            [] ->
              info "Problem solved!"
              {:ok, :solution, new_problem}
            [u | us] ->
              case problem |> values(u) |> Enum.to_list do
                [curr_value | additional_values] ->
                  debug "search/3: continuing search with #{inspect curr_value} assigned to unknown #{inspect u}, and additional values to try: #{inspect additional_values, charlists: :as_list}"
                  search(problem, us, [{{u, curr_value}, additional_values} | assignments])
                x ->
                  {:error,
                   "search/3: unexpected response from `values/2` callback: #{inspect x}"}
              end
          end
        else
          debug "search/3: problem with assignments is invalid."
          case assignments do
            [] ->
              info "No solution: invalid problem"
              {:ok, :no_solution}
            [{{curr_unk, _curr_val}, additional_vals} | prev_as] ->
              case additional_vals do
                [new_val | vals] ->
                  debug "search/3: trying next value, #{inspect new_val}, for unknown #{inspect curr_unk}. Additional values to try: #{inspect vals, charlists: :as_list}."
                  search(problem, unknowns, [{{curr_unk, new_val}, vals} | prev_as])
                [] ->
                  backtrack(problem, [curr_unk, unknowns], prev_as)
              end
          end
        end
      end

      @spec backtrack(
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment])
      :: Backtrex.result
      defp backtrack(problem, unknowns, [{{u, _old_v}, []} | assignments]) do
        debug "backtrack/3: no more values to try for #{inspect u}. Backtracking more."
        backtrack(problem, [u | unknowns], assignments)
      end
      defp backtrack(problem, unknowns, [{{u, _old_v}, [new_v | vs]} | assignments]) do
        debug "backtrack/3: trying #{inspect new_v} for unknown #{inspect u}."
        search(problem, unknowns, [{{u, new_v}, vs} | assignments])
      end
      defp backtrack(_problem, _unknowns, []), do: {:ok, :no_solution}

    end
  end
end
