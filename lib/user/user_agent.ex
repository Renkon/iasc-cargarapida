defmodule CargaRapida.UserAgent do
  use Agent

  def start_link(_opts) do
    # Try to fetch user data from other nodes
    initial_state =
      Node.list()
      |> Enum.map(&fetch_from_node/1)
      |> Enum.filter(&is_map/1)
      |> Enum.reduce(%{}, &deep_merge_users/2)

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def put_user(username, user_data) do
    entry = Map.put(user_data, :updated_at, System.system_time(:millisecond))
    Agent.update(__MODULE__, &Map.put(&1, username, entry))
    Enum.each(Node.list(), fn node ->
      :rpc.cast(node, __MODULE__, :remote_put_user, [username, entry])
    end)
  end

  def remote_put_user(username, entry) do
    Agent.update(__MODULE__, fn users ->
      case users[username] do
        nil -> Map.put(users, username, entry)
        existing ->
          # Keep the one with the latest timestamp
          if (entry[:updated_at] || 0) > (existing[:updated_at] || 0) do
            Map.put(users, username, entry)
          else
            users
          end
      end
    end)
  end

  def get_user(username) do
    Agent.get(__MODULE__, &Map.get(&1, username))
  end

  def all_users do
    Agent.get(__MODULE__, & &1)
  end

  # For syncing: fetch all users from another node
  def fetch_from_node(node) do
    :rpc.call(node, __MODULE__, :all_users, [])
  end

  # Merge user maps, keeping the latest by :updated_at
  defp deep_merge_users(map1, map2) do
    Map.merge(map1, map2, fn _k, v1, v2 ->
      if (v1[:updated_at] || 0) > (v2[:updated_at] || 0), do: v1, else: v2
    end)
  end
end
