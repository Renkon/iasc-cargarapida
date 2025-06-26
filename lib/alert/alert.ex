defmodule Alert do
  use GenServer
  defstruct [:id, :userid, :chargingpointid]

  def start_link(alert) do
    id = UUID.uuid4()
    GenServer.start_link(__MODULE__, alert, name: via_tuple(id))
  end

  @impl true
  def init(%Alert{id: id} = alert) do
    CargaRapida.AlertAgent.put_alert(id, alert)
    {:ok, alert}
  end

  defp via_tuple(id) do
    {:via, Horde.Registry, {CargaRapida.AlertRegistry, id}}
  end
end
