defmodule CargaRapida.Application do
  @moduledoc false
  use Application

  @node_prefix "cargarapida"
  @node_host "127.0.0.1"
  @node_count 3

  @node_names for i <- 1..@node_count, do: :"#{@node_prefix}#{i}@#{@node_host}"

  @port_map Enum.into(Enum.with_index(@node_names, 4000), %{})

  @impl true
  def start(_type, _args) do
    port = Map.get(@port_map, node(), 4000)

    children = [
      {Cluster.Supervisor, [topologies(), [name: CargaRapida.ClusterSupervisor]]},
      {CargaRapida.UserRegistry, [keys: :unique, members: :auto]},
      {CargaRapida.UserSupervisor, [strategy: :one_for_one, distribution_strategy: Horde.UniformQuorumDistribution, process_redistribution: :active]},
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: port, dispatch: dispatch()]},
      {CargaRapida.UserAgent, []}
    ]

    opts = [strategy: :one_for_one, name: CargaRapida.GeneralSupervisor]
    Supervisor.start_link(children, opts)
  end

  defp topologies do
    [
      carga_rapida: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: @node_names
        ]
      ]
    ]
  end

  defp dispatch do
    [
      {:_, [
        {"/ws/user", UserSocketHandler, []},
        {:_, Plug.Cowboy.Handler, {Router, []}}
      ]}
    ]
  end
end
