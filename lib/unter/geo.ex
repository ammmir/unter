defmodule Unter.Geo do
  @doc """
  Finds nearby items in an ETS table from the given coordinates up to the
  specified radius.

  The ETS table must be of the type `ordered_set` with keys of the form
  {latitude, longitude}. Values can be of any type.

  Returns a list of {key, distance, value} tuples sorted by nearest to farthest.
  """
  def find_nearby(table, lat, lng, radius \\ 5) do
    [latmin, latmax, lngmin, lngmax] = bounding_box(lat, lng, radius)
    #IO.puts "Bounding Box: #{latmin}-#{latmax}, #{lngmin}-#{lngmax}"

    # TODO: instead of walking left-to-right, start at (lat,lng) and use
    # :ets.prev and :ets.next to expand bounding box from center simultaneously
    # then stop when either radius has been reached OR the maximum number of
    # items have been found

    results = do_find_nearby table, {latmin, lngmin}, {latmax, lngmin, lngmax}

    results = Enum.map results, fn(key) ->
      [{{klat, klng}, value}] = :ets.lookup table, key

      {key, distance(lat, lng, klat, klng), value}
    end

    Enum.sort results, fn({_, d1, _}, {_, d2, _}) -> d1 < d2 end
  end

  defp do_find_nearby(table, {lat, lng}, {latmax, lngmin, lngmax}, acc \\ []) do
    key = :ets.next table, {lat, lng}
    if key == :"$end_of_table" do
      acc
    else
      {klat, klng} = key
      cond do
        klat > latmax ->
          acc
        klng >= lngmin and klng <= lngmax ->
          do_find_nearby table, {klat, klng}, {latmax, lngmin, lngmax}, [{klat, klng} | acc]
        true ->
          do_find_nearby table, {klat, klng}, {latmax, lngmin, lngmax}, acc
      end
    end
  end

  defp bounding_box(lat, lng, radius) do
    # 111.2 km/degree average for all latitudes (good enough)
    d = radius/2.0 * 1/111.2
    latmin = lat - d
    latmax = lat + d

    # km/degree varies much more by longitude, so let's be a bit more accurate
    # https://en.wikipedia.org/wiki/Longitude#Length_of_a_degree_of_longitude
    abslat = abs(lat)
    lng_deg_per_km = cond do
      abslat < 15 -> 1/111.32
      abslat < 30 -> 1/107.55
      abslat < 45 -> 1/96.486
      abslat < 60 -> 1/78.847
      abslat < 75 -> 1/55.8
      abslat < 90 -> 1/29.9
      true        -> 0
    end

    d = radius/2.0 * lng_deg_per_km
    lngmin = lng - d
    lngmax = lng + d

    [latmin, latmax, lngmin, lngmax]
  end

  defp distance(reflat, reflng, lat, lng) do
    # convert degrees to radians
    reflat = reflat * 0.0174532925
    reflng = reflng * 0.0174532925
    lat = lat * 0.0174532925
    lng = lng * 0.0174532925

    # sort by distance using equirectangular approximation
    p1 = (reflng - lng) * :math.cos(0.5*(reflat + lat))
    p2 = reflat - lat
    6371000 * :math.sqrt(p1*p1 + p2*p2) # meters
  end
end
