defmodule User do
  use GenServer
  defstruct [:username, :password, :socket_pid]

  def start_link(%User{username: username} = user) do
    GenServer.start_link(__MODULE__, user, name: via_tuple(username))
  end

  @impl true
  def init(%User{username: username} = user) do
    case CargaRapida.UserAgent.get_user(username) do
      nil ->
        CargaRapida.UserAgent.put_user(username, user)
        {:ok, user}
      saved_user ->
        {:ok, struct(User, Map.merge(Map.from_struct(user), Map.from_struct(saved_user)))}
    end
  end

  @impl true
  def handle_call(:get_password, _from, %User{password: password} = state) do
    {:reply, password, state}
  end

  @impl true
  def handle_cast({:register_socket, socket_pid}, state) do
    new_state = %{state | socket_pid: socket_pid}
    CargaRapida.UserAgent.put_user(state.username, new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:unregister_socket, state) do
    new_state = %{state | socket_pid: nil}
    CargaRapida.UserAgent.put_user(state.username, new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:send_ws, message}, %{socket_pid: pid} = state) when is_pid(pid) do
    send(pid, {:send, message})
    {:noreply, state}
  end
  def handle_cast({:send_ws, _}, state), do: {:noreply, state}

  defp via_tuple(username) do
    {:via, Horde.Registry, {CargaRapida.UserRegistry, username}}
  end
end
