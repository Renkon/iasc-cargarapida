defmodule CargaRapida.StationManager do
  def create_timeslot(types_with_power, start_time_str, station, duration_min) do
    {:ok, start_time, _offset} = DateTime.from_iso8601(start_time_str)
    end_time = DateTime.add(start_time, round(duration_min * 60), :second)

    Enum.map(types_with_power, fn {type, kw} ->
      id = UUID.uuid4()

      case CargaRapida.ChargingPointSupervisor.create(id, start_time, station, end_time, type, kw) do
        {:ok, _pid} ->
          %{
            status: "ok",
            id: id,
            type: type,
            power: kw,
            start_time: DateTime.to_iso8601(start_time),
            station: station,
            duration_min: duration_min,
            end_time: DateTime.to_iso8601(end_time)
          }
        {:error, {:already_started, _pid}} ->
          %{
            status: "error",
            id: id,
            type: type,
            power: kw,
            code: "already_exists",
            message: "A charging point with this ID already exists"
          }
        {:error, reason} ->
          %{
            status: "error",
            id: id,
            type: type,
            power: kw,
            code: inspect(reason),
            message: "Failed to create charging point due to an internal error."
          }
      end
    end)
  end
end
