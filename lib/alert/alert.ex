defmodule Alert do
  use GenServer
  defstruct [:id, :start_time, :end_time, :user_id, :type, :min_power, :station]

  def start_link(%Alert{} = alert) do
    GenServer.start_link(__MODULE__, alert, name: via_tuple(alert.id))
  end

  @impl true
  def init(alert) do
    CargaRapida.AlertAgent.put_alert(alert.id, alert)
    {:ok, alert}
  end

  defp via_tuple(id) do
    {:via, Horde.Registry, {CargaRapida.AlertRegistry, id}}
  end
end
