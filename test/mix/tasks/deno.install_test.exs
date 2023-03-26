defmodule Mix.Tasks.Deno.InstallTest do
  use DenoInstaller.Case, async: true

  alias Mix.Tasks.Deno.Install

  test "default" do
    assert [] == Install.parse_arguments([])
  end

  test "all flags" do
    assert [location: :tmp, source: "build", version: "1.0.0"] ==
             "--location /tmp --source build --tmp --version 1.0.0"
             |> OptionParser.split()
             |> Install.parse_arguments()
  end

  test "custom location and version" do
    assert [location: "/tmp-location", source: "cargo", version: "1.2.1"] ==
             "--location /tmp-location --source cargo --version 1.2.1"
             |> OptionParser.split()
             |> Install.parse_arguments()
  end
end
