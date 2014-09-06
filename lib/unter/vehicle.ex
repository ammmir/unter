defmodule Unter.Vehicle do
  alias Unter.Geo
  alias Unter.Ride

  defstruct plate: nil,
            make: nil,
            model: nil,
            color: nil,
            capacity: 0

  @doc """
  Get the vehicle server PID for the given license plate.

  Returns {:ok, pid} on success, otherwise {:error, :no_proc}.
  """
  def get(plate) do
    case :ets.lookup :vehicles, plate do
      [{^plate, pid}] -> {:ok, pid}
      _               -> {:error, :no_proc}
    end
  end

  @doc """
  Returns a list of nearby available vehicles, along with their locations, and
  distance to the user. This is useful for displaying vehicles on a map.
  """
  def find_near({lat, lng}, radius \\ 5) do
    keys = Geo.find_nearby :vehicle_positions, lat, lng, radius
    Enum.map keys, fn({location, distance, plate}) ->
      {:ok, info} = get_info plate

      %{
        vehicle: info.vehicle,
        location: location,
        distance: distance
      }
    end
  end

  @doc """
  Reserves a vehicle for the given user and number of passengers.

  Returns {:ok, vehicle} on success, otherwise {:error, :not_available}.
  """
  def reserve(user, location, num_pax, destination) do
    if Ride.user_riding? user do
      {:error, :already_reserved}
    else
      nearby = find_near location, 10 # TODO: parametrize radius

      if Enum.count(nearby) > 0 do
        case do_reserve user, location, num_pax, destination, nearby do
          [vehicle] -> {:ok, vehicle}
          nil       -> {:error, :not_available}
        end
      else
        {:error, :not_available}
      end
    end
  end

  defp do_reserve(user, location, num_pax, destination, nearby) do
    if nearby == [] do
      nil
    else
      [result | vehicles] = nearby

      case get result.vehicle.plate do
        {:ok, pid} ->
          case GenServer.call pid, {:reserve, user, location, num_pax, destination} do
            :ok -> [result.vehicle]
            _   -> do_reserve user, location, num_pax, destination, vehicles
          end
        _ ->
          do_reserve user, location, num_pax, destination, vehicles
      end
    end
  end

  @doc """
  Obtains the current state of a vehicle.
  """
  def get_info(plate) do
    {:ok, pid} = get plate
    GenServer.call pid, :info
  end

  @doc """
  Updates the current location of a vehicle.
  """
  def update_position(plate, {lat, lng} = location) do
    {:ok, pid} = get plate
    GenServer.cast pid, {:update_position, location}
  end
end
