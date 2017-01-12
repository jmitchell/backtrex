defmodule Backtrex do

  @typedoc """
  A puzzle with a finite set of `unknown`s, possible `assignment`s
  for each, and an invariant property.

  Each type of `problem` must have facilities for:

  1. enumerating its unknowns (see `c:unknowns`),
  2. enumerating `value`s that could be assigned to a specified
  `unknown` in a solution (see `c:initial_value` and `c:next_value`),
  3. incorporating proposed `assignments` (see
  `c:with_assignments`), and
  4. checking whether the invariant holds (see `c:valid?`).
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

  @type result :: {:ok, :solution, problem}
                | {:ok, :no_solution}

  @callback unknowns(problem) :: [unknown]
  @callback initial_value(problem, unknown) :: value
  @callback next_value(problem, unknown, value) :: maybe_value
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
      def solve(problem), do: search(problem, unknowns(problem), [])

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
          {:ok, :solution, problem}
        else
          init_val = problem |> initial_value(unknown)
          search(problem, us, [{unknown, init_val}])
        end
      end
      def search(problem, unknowns, assignments) do
        new_problem = problem |> with_assignments(assignments)
        if new_problem |> valid? do
          case new_problem |> unknowns do
            [] ->
              {:ok, :solution, new_problem}
            [u | us] ->
              value = problem |> initial_value(u)
              search(problem, us, [{u, value} | assignments])
          end
        else
          case assignments do
            [] ->
              {:ok, :no_solution}
            [{curr_unk, curr_val} | prev_as] ->
              case new_problem |> next_value(curr_unk, curr_val) do
                :none ->
                  # Invalid assignment and no additional values to
                  # try. Backtracking...
                  backtrack(problem, [curr_unk, unknowns], prev_as)
                {:ok, new_val} ->
                  # Invalid assignment; trying next value instead.
                  search(problem, unknowns, [{curr_unk, new_val} | prev_as])
              end
          end
        end
      end

      @spec backtrack(
        Backtrex.problem,
        [Backtrex.unknown],
        [Backtrex.assignment])
      :: Backtrex.result
      defp backtrack(problem, unknowns, [{u, v} | assignments]) do
        case problem |> next_value(u, v) do
          :none ->
            # No more values to try for this assignment
            # either. Continue backtracking.
            backtrack(problem, [u | unknowns], assignments)
          {:ok, new_v} ->
            search(problem, unknowns, [{u, new_v} | assignments])
        end
      end
      defp backtrack(_problem, _unknowns, []), do: {:ok, :no_solution}

    end
  end
end
