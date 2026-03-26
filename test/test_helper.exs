{:ok, _} = Application.ensure_all_started(:ex_machina)

EctoTurbo.TestRepo.start_link()
ExUnit.start()
