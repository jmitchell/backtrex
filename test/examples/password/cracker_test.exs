defmodule Backtrex.Examples.Password.Cracker.Test do
  use ExUnit.Case, async: true

  alias Backtrex.Examples.Password.Authenticator
  alias Backtrex.Examples.Password.Cracker

  describe "Cracker.solve/1" do
    def example_authenticator do
      {:ok, authenticator} = Authenticator.create('dog')
      authenticator
    end

    def expected_solution do
      %Authenticator{secret: 'dog', guess: 'dog'}
    end

    test "crack 3-character password" do
      {:ok, :solution, actual} =
        example_authenticator()
        |> Cracker.solve

      assert actual == expected_solution()
    end
  end
end
