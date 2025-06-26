defmodule CargaRapida.BaseHordeRegistry do
  defmacro __using__(_opts) do
    quote do
      use Horde.Registry

      def start_link(init_arg) do
        Horde.Registry.start_link(__MODULE__, init_arg, name: __MODULE__)
      end

      @impl true
      def init(init_arg) do
        [members: members()]
        |> Keyword.merge(init_arg)
        |> Horde.Registry.init()
      end

      defp members() do
        Enum.map(Node.list([:this, :visible]), &{__MODULE__, &1})
      end
    end
  end
end
