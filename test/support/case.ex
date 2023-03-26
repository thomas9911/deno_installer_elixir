defmodule DenoInstaller.Case do
  use ExUnit.CaseTemplate

  setup _ do
    Mox.stub_with(DenoInstaller.System.Mock, DenoInstaller.System.Default)
    :ok
  end
end
