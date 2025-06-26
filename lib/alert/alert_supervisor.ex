defmodule CargaRapida.AlertSupervisor do
  use CargaRapida.BaseHordeSupervisor

  def create(username, password) do
    user = %User{username: username, password: password}
    Horde.DynamicSupervisor.start_child(__MODULE__, {User, user})
  end

end
