defmodule Unter.Vehicle.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], [name: __MODULE__]
  end

  def init([]) do
    children = [
      worker(Unter.Vehicle.Server, [])
    ]

    # ETS table for vehicle id to pid lookups
    :ets.new :vehicles, [:set, :public, :named_table]

    # ETS table for {lat,lng} -> vehicle id searches
    :ets.new :vehicle_positions, [:ordered_set, :public, :named_table]

    supervise children, strategy: :simple_one_for_one
  end

  def start_vehicle(vehicle, location) do
    {:ok, pid} = Supervisor.start_child __MODULE__, [vehicle, location]

    # TODO: don't start if it's already running
    :ets.insert_new :vehicles, {vehicle.plate, pid}

    {:ok, pid}
  end
end
