defmodule CargaRapida.UserSupervisor do
  use Horde.DynamicSupervisor

  def start_link(init_arg) do
    Horde.DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    [members: members()]
    |> Keyword.merge(init_arg)
    |> Horde.DynamicSupervisor.init()
  end

  def start_child(child_spec) do
    Horde.DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

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

  defp members do
    Enum.map(Node.list([:this, :visible]), &{__MODULE__, &1})
  end
end
