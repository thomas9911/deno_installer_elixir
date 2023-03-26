defmodule DenoInstaller.Config do
  defstruct version: :latest, source: "infer", location: :default, out: :stdout

  alias DenoInstaller.System

  @type t :: %__MODULE__{
          version: :latest | binary,
          source: binary,
          location: :default | :tmp | binary,
          out: :stdout | :string
        }

  @commands %{
    "sh" => "curl -fsSL https://deno.land/install.sh | sh",
    "powershell" => ~s[irm https://deno.land/install.ps1 | iex],
    "cargo" => "cargo install deno",
    "scoop" => "scoop install deno",
    "brew" => "brew install deno",
    "pacman" => "pacman -S deno",
    "zypper" => "zypper install -y deno",
    "asdf" => "asdf plugin add deno && asdf install"
  }

  @package_managers ["scoop", "brew", "pacman", "zypper"]

  @installation_methods @commands |> Map.keys() |> Enum.concat(["shell", "build"]) |> Enum.sort()

  @versioned_commands %{
    "sh" => "{{COMMAND}} -s v{{VERSION}}",
    "powershell" => ~s[$v="{{VERSION}}"; {{COMMAND}}],
    "cargo" => "{{COMMAND}} --version {{VERSION}}",
    "scoop" => "{{COMMAND}}",
    "brew" => "{{COMMAND}}@{{VERSION}}",
    "pacman" => "{{COMMAND}}",
    "zypper" => "{{COMMAND}}={{VERSION}}",
    "asdf" => "{{COMMAND}}"
  }

  @on_windows match?({:win32, _}, :os.type())

  @spec new(map | keyword) :: t()
  def new(args \\ %{}) do
    struct(__MODULE__, args)
  end

  @spec resolve_source(t()) :: t()
  def resolve_source(%__MODULE__{source: "infer"} = config) do
    source =
      if System.use_asdf?() do
        "asdf"
      else
        Enum.reduce_while(@package_managers, "shell", fn executable, acc ->
          if System.executable_found?(executable) do
            {:halt, executable}
          else
            {:cont, acc}
          end
        end)
      end

    Map.put(config, :source, source)
  end

  def resolve_source(%__MODULE__{} = config) do
    config
  end

  @spec install_command(t()) :: {:ok, binary} | {:error, binary}
  def install_command(%__MODULE__{source: "infer"} = config) do
    config
    |> resolve_source()
    |> install_command()
  end

  def install_command(%__MODULE__{source: "build"} = config) do
    if System.executable_found?("cargo") do
      config
      |> Map.put(:source, "cargo")
      |> install_command()
    else
      {:error, "cargo is not installed"}
    end
  end

  if @on_windows do
    def install_command(%__MODULE__{source: "shell"} = config) do
      config
      |> Map.put(:source, "powershell")
      |> install_command()
    end
  else
    def install_command(%__MODULE__{source: "shell"} = config) do
      if System.executable_found?("curl") and System.executable_found?("unzip") do
        config
        |> Map.put(:source, "sh")
        |> install_command()
      else
        {:error, "curl and unzip are required to install deno"}
      end
    end
  end

  def install_command(%__MODULE__{source: command, version: :latest})
      when command in @installation_methods do
    Map.fetch(@commands, command)
  end

  def install_command(%__MODULE__{source: command, version: version})
      when command in @installation_methods and is_binary(version) do
    command_template = Map.fetch!(@versioned_commands, command)
    variables = %{"VERSION" => version, "COMMAND" => Map.fetch!(@commands, command)}

    {:ok,
     Enum.reduce(
       variables,
       command_template,
       fn {key, value}, template ->
         String.replace(template, "{{#{key}}}", value)
       end
     )}
  end

  def install_command(%__MODULE__{source: command}) when command not in @installation_methods do
    {:error, "invalid source should be one of #{Enum.join(@installation_methods, ", ")}"}
  end

  def format_install_options(config) do
    config
    |> Map.from_struct()
    |> Enum.flat_map(&to_install_option/1)
  end

  defp to_install_option({:out, :stdout}) do
    [into: IO.stream()]
  end

  defp to_install_option({:location, :tmp}) do
    [env: [{"DENO_INSTALL", System.tmp_dir!()}]]
  end

  defp to_install_option({:location, location}) when is_binary(location) do
    [env: [{"DENO_INSTALL", location}]]
  end

  defp to_install_option(_) do
    []
  end

  @spec on_windows?() :: boolean
  def on_windows? do
    @on_windows
  end

  @spec allowed_installation_methods() :: [binary]
  def allowed_installation_methods do
    @installation_methods
  end
end
