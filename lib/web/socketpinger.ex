defmodule CargaRapida.SocketPinger do
  use GenServer

  @interval 5_000  # 5 segundos

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule_work()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:work, state) do
    do_something()

    schedule_work()
    {:noreply, state}
  end

  ## Función privada

  defp schedule_work do
    Process.send_after(self(), :work, @interval)
  end

  defp do_something do
    CargaRapida.StationManager.ping_all_users()
  end
end
