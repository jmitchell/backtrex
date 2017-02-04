defmodule Backtrex.Examples.Password.Authenticator do
  @moduledoc """
  Simulates a naive password authenticator.
  """
  alias Backtrex.Examples.Password.Authenticator

  @typedoc "Passwords are either character lists or strings."
  @type password :: [char()] | String.t

  @typedoc "Password authenticator with a secret."
  @type t :: %Authenticator{secret: [char()]}

  @doc "`Authenticator` struct with a secret and a guess."
  # TODO: Allow Backtrex client state to be threaded through callbacks, so
  # `guess` doesn't have to be tracked here. Merging guessed Sudoku cells works
  # well, but it's a terrible fit here.
  defstruct secret: [], guess: []

  @doc """
  Create `Backtrex.Examples.Password.Authenticator` with specified secret
  password.
  """
  @spec create(password) :: {:ok, t} | {:error, any()}
  def create(password) when is_list(password) do
    {:ok, %Authenticator{secret: password}}
  end
  def create(password) when is_binary(password) do
    password |> to_charlist |> create
  end

  @doc """
  Check whether the guessed password authenticates.

  WARNING: A proper password authentication mechanism should use a proper
  cryptographic password hash function with salt rather than basic string
  comparison. This is purely for demonstration purposes.
  """
  @spec authenticates?(t) :: boolean()
  def authenticates?(authenticator) do
    authenticator.guess == authenticator.secret
  end
end
