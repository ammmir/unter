defmodule Unter.Ride do
  @doc """
  Returns whether or not the user has an active ride.
  """
  def user_riding?(user) do
    case get_vehicle user do
      {:ok, vehicle} -> true
      _              -> false
    end
  end

  @doc """
  Returns the vehicle the user in which the user is riding.
  """
  def get_vehicle(user) do
    GenServer.call __MODULE__.Server, {:get_vehicle, user}
  end

  @doc """
  Marks the user as riding.
  """
  def start(user, vehicle) do
    GenServer.cast __MODULE__.Server, {:start_ride, user, vehicle}
  end

  @doc """
  Marks the user as no longer riding.
  """
  def stop(user) do
    GenServer.cast __MODULE__.Server, {:stop_ride, user}
  end
end
