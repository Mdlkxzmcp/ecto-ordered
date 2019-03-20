Logger.configure(level: :error)

defmodule EctoOrderedTest.Repo do
  use Ecto.Repo,
    otp_app: :ecto_ordered,
    adapter: Ecto.Adapters.Postgres
end

defmodule EctoOrdered.TestCase do
  use ExUnit.CaseTemplate

  defmacro debug(do: block) do
    quote do
      Logger.configure(level: :debug)
      unquote(block)
      Logger.configure(level: :error)
    end
  end

  using do
    quote do
      import EctoOrdered.TestCase, only: :macros
    end
  end
end

Mix.Task.run("ecto.drop", ~w(-r EctoOrderedTest.Repo))
Mix.Task.run("ecto.create", ~w(-r EctoOrderedTest.Repo))
Mix.Task.run("ecto.migrate", ~w(-r EctoOrderedTest.Repo))

EctoOrderedTest.Repo.start_link()
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EctoOrderedTest.Repo, :manual)
