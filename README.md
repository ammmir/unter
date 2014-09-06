# Unter – Ridematching Server

Unter is an Elixir application that you can use to start your own real-time ridematching service to compete with the big guys. You'll be miles ahead of them with speed, concurrency, and fault-tolerance advantages of Erlang!

Okay, this is just a fun experiment of how one might design the ridematching backend of such a service. It doesn't currently expose an HTTP API, so it must be used from Elixir/Erlang, but it should be trivial to implement.

See `test/unter_test.exs` for usage examples.


## Features

  * One Erlang process per vehicle
  * Vehicle locations are stored in an `ordered_set` ETS table for fast lookups by location (bounding box)
  * Reservations take into account vehicles' passanger capacity

## API Example

```iex
iex> bug = %Vehicle{plate: "BEETLE1", make: "Volkswagen", model: "Beetle (Type 1)", capacity: 3}
%Unter.Vehicle{capacity: 3, color: nil, make: "Volkswagen",
 model: "Beetle (Type 1)", plate: "BEETLE1"}
iex> Vehicle.Supervisor.start_vehicle bug, {37.803913, -122.449264}
{:ok, #PID<0.83.0>}

iex> my_loc = {37.8019812, -122.4478909}
{37.8019812, -122.4478909}
iex> ferry_building = {37.795299, -122.393939}
{37.795299, -122.393939}

iex> user = %{id: "1", full_name: "Jimmy Jimz"}     
%{full_name: "Jimmy Jimz", id: "1"}
iex> Vehicle.reserve user, my_loc, 2, ferry_building
{:ok,
 %Unter.Vehicle{capacity: 3, color: nil, make: "Volkswagen",
  model: "Beetle (Type 1)", plate: "BEETLE1"}}

iex> Vehicle.update_position "BEETLE1", {37.795299, -122.393939}
:ok  
```


## TODO

  * Erlang distribution
    * Distribute vehicle processes and location tables across multiple nodes
    * Keep users/vehicles in the same region on the same node to reduce distribution traffic
  * More efficient nearest neighbor search (Z-order/Hilbert curve, Voronoi cells?) with millions of vehicles/users