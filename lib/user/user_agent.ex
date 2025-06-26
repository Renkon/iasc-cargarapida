defmodule CargaRapida.UserAgent do
  use CargaRapida.BaseAgent, entity_key: :username, timestamp_key: :updated_at

  def put_user(username, user_data) do
    put_entry(username, user_data)
  end

  def get_user(username) do
    get_entry(username)
  end
end
