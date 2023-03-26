defmodule DenoInstaller.System do
  @moduledoc """
  Wrappers around calls to the system
  """

  @callback use_asdf?() :: boolean
  @callback executable_found?(binary) :: boolean
  @callback on_windows?() :: boolean
  @callback tmp_dir!() :: binary

  alias DenoInstaller.System.Default

  @spec use_asdf?() :: boolean
  def use_asdf? do
    backend().use_asdf?()
  end

  @spec executable_found?(binary) :: boolean
  def executable_found?(exec) do
    backend().executable_found?(exec)
  end

  @spec on_windows?() :: boolean
  def on_windows? do
    backend().on_windows?()
  end

  @spec tmp_dir!() :: binary
  def tmp_dir! do
    backend().tmp_dir!()
  end

  defp backend do
    Application.get_env(:deno_installer, :system, Default)
  end
end
