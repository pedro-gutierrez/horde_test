defmodule HordeTest.DistSup do
  use Horde.Supervisor

  def init(options) do
    Process.flag(:trap_exit, true)
    {:ok, Keyword.put(options, :members, get_members())}
  end

  defp get_members() do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {HordeTest.DistSup, node} end)
  end
  

end
