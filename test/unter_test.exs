defmodule UnterTest do
  use ExUnit.Case
  alias Unter.Vehicle
  alias Unter.User

  test "vehicles" do
    user1 = %User{id: "1", full_name: "Jimmy Jimz"}
    user2 = %User{id: "2", full_name: "Sally Sass"}

    v1 = %Vehicle{plate: "ROADSTR", make: "Tesla", model: "Roadster", color: "red", capacity: 1}
    v2 = %Vehicle{plate: "MMMLUV", make: "BMW", model: "M3", color: "white", capacity: 4}
    v3 = %Vehicle{plate: "LOLOTUS", make: "Lotus", model: "Evora", color: "grey", capacity: 3}
    v4 = %Vehicle{plate: "SLOWPOK", make: "Toyota", model: "Prius", color: "white", capacity: 4}

    # Lyon St, SF
    {:ok, _v1_pid} = Vehicle.Supervisor.start_vehicle v1, {37.803913, -122.449264}

    # Lincoln Blvd, SF
    {:ok, _v2_pid} = Vehicle.Supervisor.start_vehicle v2, {37.799989, -122.452950}

    # Marina Blvd, SF
    {:ok, _v3_pid} = Vehicle.Supervisor.start_vehicle v3, {37.805342, -122.445882}

    # East Rd, Sausalito
    {:ok, _v4_pid} = Vehicle.Supervisor.start_vehicle v4, {37.835196, -122.477749}

    # Palace of Fine Arts, SF
    my_loc = {37.8019812, -122.4478909}

    # find nearby cars within 5km
    cars = Vehicle.find_near my_loc, 5

    assert Enum.count(cars) == 3
    assert Enum.at(cars, 0).vehicle.plate == v1.plate
    assert Enum.at(cars, 1).vehicle.plate == v3.plate
    assert Enum.at(cars, 2).vehicle.plate == v2.plate

    # user1: reserve a car for 1 passenger to Ferry Building
    {:ok, rv1} = Vehicle.reserve user1, my_loc, 1, {37.795299, -122.393939}
    assert rv1.plate == v1.plate

    # user1: attempt to reserve another car
    assert {:error, :already_reserved} == Vehicle.reserve user1, my_loc, 1, {37.795299, -122.393939}

    # user2: reserve a car for 10 passengers to Ferry Building
    assert {:error, :not_available} == Vehicle.reserve user2, my_loc, 10, {37.795299, -122.393939}

    # user2: reserve a car for 1 passenger to Ferry Building
    {:ok, rv2} = Vehicle.reserve user2, my_loc, 1, {37.795299, -122.393939}
    assert rv2.plate == v3.plate

    if false do
    try do
      :observer.start
      IO.write "Press any key to exit..."
      IO.read :line
      :observer.stop
    rescue
      _ ->
    end
    end
  end
end

