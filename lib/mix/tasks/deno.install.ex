defmodule Mix.Tasks.Deno.Install do
  @moduledoc "Installs Deno"
  @shortdoc "Installs Deno"

  use Mix.Task

  @command_arguments [location: :string, tmp: :boolean, source: :string, version: :string]

  @impl Mix.Task
  def run(args) do
    config_base()
    |> Keyword.merge(parse_arguments(args))
    |> DenoInstaller.Config.new()
    |> DenoInstaller.install()
    |> case do
      {:ok, _} -> :ok
      {:error, error_code} -> Mix.raise("error installing Deno", exit_status: error_code)
    end

    :ok
  end

  @spec parse_arguments(list) :: list
  def parse_arguments(args) do
    {out, _} = OptionParser.parse!(args, strict: @command_arguments)

    case Keyword.pop(out, :tmp) do
      {true, out} -> Keyword.put(out, :location, :tmp)
      {_, out} -> out
    end
  end

  @spec config_base() :: keyword
  def config_base do
    Application.get_env(:deno_installer, :install_options, [])
  end
end
