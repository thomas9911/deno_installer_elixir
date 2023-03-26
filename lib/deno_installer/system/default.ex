defmodule DenoInstaller.System.Default do
  @behaviour DenoInstaller.System

  @on_windows match?({:win32, _}, :os.type())

  @impl true
  def use_asdf? do
    File.exists?(".tool-versions") and executable_found?("asdf")
  end

  @impl true
  def executable_found?(exec) do
    is_binary(System.find_executable(exec))
  end

  @impl true
  def on_windows? do
    @on_windows
  end

  @impl true
  def tmp_dir! do
    System.tmp_dir!()
  end
end
