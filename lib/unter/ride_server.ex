defmodule Unter.Ride.Server do
  use GenServer

  def start_link do
    GenServer.start __MODULE__, [], [name: __MODULE__]
  end

  def init([]) do
    state = %{
      num_active: 0
    }

    # ETS table keeping track of rides in progress
    :ets.new :rides, [:set, :public, :named_table]

    {:ok, state}
  end

  def handle_call({:get_vehicle, user}, _from, state) do
    reply = case :ets.lookup :rides, user do
      [{_, vehicle}] -> {:ok, vehicle}
      _              -> {:error, :not_found}
    end

    {:reply, reply, state}
  end

  def handle_cast({:start_ride, user, vehicle}, state) do
    :ets.insert_new :rides, {user, vehicle}

    {:noreply, %{state | num_active: state.num_active + 1}}
  end

  def handle_cast({:stop_ride, user}, state) do
    :ets.delete :rides, user

    {:noreply, %{state | num_active: state.num_active - 1}}
  end
end
