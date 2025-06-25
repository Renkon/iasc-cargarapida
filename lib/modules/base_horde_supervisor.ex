defmodule CargaRapida.BaseHordeSupervisor do
  defmacro __using__(_opts) do
    quote do
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

      defp members do
        Enum.map(Node.list([:this, :visible]), &{__MODULE__, &1})
      end
    end
  end
end
