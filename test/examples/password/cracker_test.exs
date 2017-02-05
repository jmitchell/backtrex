defmodule Backtrex.Examples.Password.Cracker.Test do
  use ExUnit.Case, async: true

  alias Backtrex.Examples.Password.Authenticator
  alias Backtrex.Examples.Password.Cracker

  @password 'dog'

  describe "Cracker.solve/1" do
    def example_authenticator do
      {:ok, authenticator} = Authenticator.create(@password)
      authenticator
    end

    def expected_solution do
      %Authenticator{secret: @password, guess: @password}
    end

    test "crack 3-character password" do
      {:ok, :solution, actual} =
        example_authenticator()
        |> Cracker.solve

      assert actual == expected_solution()
    end
  end
end
