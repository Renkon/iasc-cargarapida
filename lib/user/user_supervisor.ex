defmodule CargaRapida.UserSupervisor do
  use CargaRapida.BaseHordeSupervisor

  def create(username, password) do
    user = %User{username: username, password: password}
    Horde.DynamicSupervisor.start_child(__MODULE__, {User, user})
  end

  def send_ws_message(username, message) do
    case Horde.Registry.lookup(CargaRapida.UserRegistry, username) do
      [{pid, _}] -> GenServer.cast(pid, {:send_ws, message})
      _ -> :error
    end
  end
end
