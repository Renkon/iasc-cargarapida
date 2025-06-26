defmodule CargaRapida.StationManager do
  def create_timeslot(types_with_power, datetime_str, station, duration_min) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(datetime_str)
    offer_endtime = DateTime.add(DateTime.utc_now(), round(duration_min * 60), :second)

    Enum.map(types_with_power, fn {type, kw} ->
      case CargaRapida.ChargingPointSupervisor.create(datetime, station, offer_endtime, type, kw) do
        {:ok, pid} -> {:ok, pid}
        {:error, {:already_started, _pid}} -> {:error, :already_exists}
        error -> error
      end
    end)
  end
end
