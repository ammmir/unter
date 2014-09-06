defmodule Unter.Vehicle.Server do
  use GenServer
  alias Unter.Ride

  def start_link(vehicle, location) do
    GenServer.start __MODULE__, [vehicle, location]
  end

  def init([vehicle, location]) do
    state = %{
      vehicle: vehicle,
      location: location,
      available: true,
      to_location: nil,
      to_user: nil
    }

    :ets.insert :vehicle_positions, {location, state.vehicle.plate}

    {:ok, state}
  end

  def handle_call({:reserve, user, location, num_pax, destination}, _from, state) do
    if state.available and num_pax <= state.vehicle.capacity do
      state = %{state |
        available: false,
        to_location: destination,
        to_user: user
      }

      Ride.start user, state.vehicle

      # TODO: send notification to vehicle for pickup request at location

      {:reply, :ok, state}
    else
      {:reply, :not_available, state}
    end
  end

  def handle_call(:info, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call(:status, _from, state) do
    if state.available do
      status = :available
    else
      status = :unavailable
    end

    {:reply, {status, state.location}, state}
  end

  def handle_cast({:unreserve, user}, state) do
    state = %{state | available: true, to_location: nil, to_user: nil}
    Ride.stop user

    {:noreply, state}
  end

  def handle_cast({:update_position, location}, state) do
    :ets.delete :vehicle_positions, state.location
    :ets.insert :vehicle_positions, {location, state.vehicle.plate}

    {:noreply, %{state | location: location}}
  end
end
