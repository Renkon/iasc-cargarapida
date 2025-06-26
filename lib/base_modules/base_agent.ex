defmodule CargaRapida.BaseAgent do
  defmacro __using__(opts) do
    quote do
      use Agent

      @entity_key unquote(opts[:entity_key] || :key)
      @timestamp_key unquote(opts[:timestamp_key] || :updated_at)

      def start_link(_opts) do
        initial_state =
          Node.list()
          |> Enum.map(&fetch_from_node/1)
          |> Enum.filter(&is_map/1)
          |> Enum.reduce(%{}, &deep_merge_entries/2)

        Agent.start_link(fn -> initial_state end, name: __MODULE__)
      end

      def put_entry(key, data) do
        entry = Map.put(data, @timestamp_key, System.system_time(:millisecond))
        Agent.update(__MODULE__, &Map.put(&1, key, entry))
        Enum.each(Node.list(), fn node ->
          :rpc.cast(node, __MODULE__, :remote_put_entry, [key, entry])
        end)
      end

      def remote_put_entry(key, entry) do
        Agent.update(__MODULE__, fn entries ->
          case entries[key] do
            nil -> Map.put(entries, key, entry)
            existing ->
              if Map.get(entry, @timestamp_key, 0) > Map.get(existing, @timestamp_key, 0) do
                Map.put(entries, key, entry)
              else
                entries
              end
          end
        end)
      end

      def delete_entry(key) do
        Agent.update(__MODULE__, &Map.delete(&1, key))
        Enum.each(Node.list(), fn node ->
          :rpc.cast(node, __MODULE__, :remote_delete_entry, [key])
        end)
      end

      def remote_delete_entry(key) do
        Agent.update(__MODULE__, &Map.delete(&1, key))
      end

      def get_entry(key) do
        Agent.get(__MODULE__, &Map.get(&1, key))
      end

      def all_entries do
        Agent.get(__MODULE__, & &1)
      end

      def fetch_from_node(node) do
        :rpc.call(node, __MODULE__, :all_entries, [])
      end

      defp deep_merge_entries(map1, map2) do
        Map.merge(map1, map2, fn _k, v1, v2 ->
          if Map.get(v1, @timestamp_key, 0) > Map.get(v2, @timestamp_key, 0), do: v1, else: v2
        end)
      end
    end
  end
end
