defmodule Backtrex.Examples.Password.Cracker do
  @moduledoc false

  use Backtrex

  alias Backtrex.Examples.Password.Authenticator

  def unknowns(_authenticator) do
    # assume password is 3 characters long
    0..2
  end

  def values(_authenticator, _index), do: ?a..?z

  def assign(authenticator, index, value) do
    IO.puts "guess: #{inspect authenticator.guess}"
    new_guess = List.replace_at(authenticator.guess, index, value)
    %Authenticator{authenticator | guess: new_guess}
  end

  def valid?(authenticator) do
    Authenticator.authenticates?(authenticator)
  end
end
