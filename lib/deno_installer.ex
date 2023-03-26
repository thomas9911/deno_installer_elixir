defmodule DenoInstaller do
  alias DenoInstaller.Config

  def install(config \\ %{})

  def install(%Config{} = config) do
    options = Config.format_install_options(config)

    case Config.install_command(config) do
      {:ok, command} ->
        command
        |> System.shell(options)
        |> format_output()

      {:error, error} ->
        {:error, error}
    end
  end

  def install(opts) when is_map(opts) or is_list(opts) do
    opts
    |> Config.new()
    |> install()
  end

  defp format_output({%IO.Stream{}, 0}) do
    {:ok, ""}
  end

  defp format_output({data, 0}) do
    {:ok, data}
  end

  defp format_output({_, error_code}) when error_code != 0 do
    {:error, error_code}
  end
end
