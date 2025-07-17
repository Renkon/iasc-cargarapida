defmodule UserSocketHandler do
  @behaviour :cowboy_websocket

  # Called on HTTP upgrade to websocket
  def init(req, _opts) do
    {:cowboy_websocket, req, %{user: nil}}
  end

  # Called when websocket is established
  def websocket_init(state) do
    {:ok, state}
  end

  # Handle incoming websocket messages from client
  def websocket_handle({:text, msg}, state) do
    case msg do
      "pong" ->
        {:ok, state}

      _ ->
        # Expecting JSON like {"user": "foo"}
        case Jason.decode(msg) do
          {:ok, %{"user" => username}} ->
            # Register this websocket PID in the User process
            case Horde.Registry.lookup(CargaRapida.UserRegistry, username) do
              [{pid, _}] ->
                GenServer.cast(pid, {:register_socket, self()})
                {:reply, {:text, "registered"}, Map.put(state, :user, username)}
              _ ->
                {:reply, {:text, "user not found"}, state}
            end
          _ ->
            {:reply, {:text, "invalid"}, state}
        end
    end
  end

  def websocket_handle(_data, state), do: {:ok, state}

  # Handle messages sent from your app to the socket process
  def websocket_info({:send, payload}, state) do
    {:reply, {:text, payload}, state}
  end
  def websocket_info(_info, state), do: {:ok, state}

  def terminate(_reason, _req, state) do
  # Remove socket_pid from user process if registered
  case state[:user] do
    nil -> :ok
    username ->
      case Horde.Registry.lookup(CargaRapida.UserRegistry, username) do
        [{pid, _}] -> GenServer.cast(pid, :unregister_socket)
        _ -> :ok
      end
    end
    :ok
  end
end
