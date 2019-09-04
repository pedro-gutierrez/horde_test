# start the current node as a manager
:ok = LocalCluster.start()
{:ok, _} = Application.ensure_all_started(:horde_test)
ExUnit.start()
