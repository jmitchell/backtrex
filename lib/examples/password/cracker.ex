defmodule Backtrex.Examples.Password.Cracker do
  @moduledoc false

  use Backtrex

  alias Backtrex.Examples.Password.Authenticator

  # TODO: Support a range of lengths rather than a single precise
  # length.
  @pw_length 3


  def unknowns(authenticator) do
    assign_count = Enum.count(authenticator.guess)
    max_index = @pw_length - 1

    if assign_count > max_index do
      []
    else
      assign_count..max_index
    end
  end

  def values(_authenticator, _index), do: ?a..?z

  def assign(authenticator, index, value) do
    new_guess = if Enum.count(authenticator.guess) == @pw_length do
      List.replace_at(authenticator.guess, index, value)
    else
      List.insert_at(authenticator.guess, index, value)
    end
    %Authenticator{authenticator | guess: new_guess}
  end

  def valid?(authenticator) do
    Enum.count(authenticator.guess) < @pw_length ||
      Authenticator.authenticates?(authenticator)
  end
end
