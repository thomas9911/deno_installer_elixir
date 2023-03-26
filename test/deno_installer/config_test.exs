defmodule DenoInstaller.ConfigTest do
  use DenoInstaller.Case, async: true

  alias DenoInstaller.Config

  setup do
    Hammox.verify_on_exit!()
  end

  test "invalid source" do
    assert {:error,
            "invalid source should be one of asdf, brew, build, cargo, pacman, powershell, scoop, sh, shell, zypper"} ==
             %{source: "testing"}
             |> Config.new()
             |> Config.install_command()
  end

  describe "resolve_source =>" do
    test "asdf" do
      DenoInstaller.System.Mock
      |> Hammox.expect(:use_asdf?, fn -> true end)

      assert %DenoInstaller.Config{source: "asdf"} = Config.resolve_source(Config.new())
    end

    test "scoop" do
      DenoInstaller.System.Mock
      |> Hammox.expect(:use_asdf?, fn -> false end)
      |> Hammox.expect(:executable_found?, 1, fn exec -> exec == "scoop" end)

      assert %DenoInstaller.Config{source: "scoop"} = Config.resolve_source(Config.new())
    end

    test "brew" do
      DenoInstaller.System.Mock
      |> Hammox.expect(:use_asdf?, fn -> false end)
      |> Hammox.expect(:executable_found?, 2, fn exec -> exec == "brew" end)

      assert %DenoInstaller.Config{source: "brew"} = Config.resolve_source(Config.new())
    end

    test "pacman" do
      DenoInstaller.System.Mock
      |> Hammox.expect(:use_asdf?, fn -> false end)
      |> Hammox.expect(:executable_found?, 3, fn exec -> exec == "pacman" end)

      assert %DenoInstaller.Config{source: "pacman"} = Config.resolve_source(Config.new())
    end

    test "zypper" do
      DenoInstaller.System.Mock
      |> Hammox.expect(:use_asdf?, fn -> false end)
      |> Hammox.expect(:executable_found?, 4, fn exec -> exec == "zypper" end)

      assert %DenoInstaller.Config{source: "zypper"} = Config.resolve_source(Config.new())
    end

    test "shell" do
      DenoInstaller.System.Mock
      |> Hammox.expect(:use_asdf?, fn -> false end)
      |> Hammox.expect(:executable_found?, 4, fn _ -> false end)

      assert %DenoInstaller.Config{source: "shell"} = Config.resolve_source(Config.new())
    end
  end

  describe "latest command =>" do
    %{
      "sh" => "curl -fsSL https://deno.land/install.sh | sh",
      "powershell" => ~s[irm https://deno.land/install.ps1 | iex],
      "cargo" => "cargo install deno",
      "scoop" => "scoop install deno",
      "brew" => "brew install deno",
      "pacman" => "pacman -S deno",
      "zypper" => "zypper install -y deno",
      "asdf" => "asdf plugin add deno && asdf install"
    }
    |> Enum.map(fn {option, command} ->
      test "#{option}" do
        assert {:ok, unquote(command)} ==
                 %{source: unquote(option)}
                 |> Config.new()
                 |> Config.install_command()
      end
    end)

    if Config.on_windows?() do
      test "shell" do
        assert {:ok, ~s[irm https://deno.land/install.ps1 | iex]} ==
                 %{source: "shell"}
                 |> Config.new()
                 |> Config.install_command()
      end
    else
      test "shell" do
        assert {:ok, "curl -fsSL https://deno.land/install.sh | sh"} ==
                 %{source: "shell"}
                 |> Config.new()
                 |> Config.install_command()
      end
    end
  end

  describe "versioned command =>" do
    %{
      "sh" => "curl -fsSL https://deno.land/install.sh | sh -s v1.0.0",
      "powershell" => ~s[$v="1.0.0"; irm https://deno.land/install.ps1 | iex],
      "cargo" => "cargo install deno --version 1.0.0",
      "scoop" => "scoop install deno",
      "brew" => "brew install deno@1.0.0",
      "pacman" => "pacman -S deno",
      "zypper" => "zypper install -y deno=1.0.0",
      "asdf" => "asdf plugin add deno && asdf install"
    }
    |> Enum.map(fn {option, command} ->
      test "#{option}" do
        assert {:ok, unquote(command)} ==
                 %{source: unquote(option), version: "1.0.0"}
                 |> Config.new()
                 |> Config.install_command()
      end
    end)
  end

  describe "format options" do
    test "default" do
      assert [into: IO.stream()] ==
               %{}
               |> Config.new()
               |> Config.format_install_options()
    end

    test "output to string" do
      assert [] == %{out: :string} |> Config.new() |> Config.format_install_options()
    end

    if Config.on_windows?() do
      test "override installation to tmp" do
        options =
          %{location: :tmp}
          |> Config.new()
          |> Config.format_install_options()

        assert IO.stream() == Keyword.fetch!(options, :into)

        assert {"DENO_INSTALL", install_location} =
                 options
                 |> Keyword.fetch!(:env)
                 |> List.first()

        assert String.ends_with?(install_location, ~s[\\Temp])
      end
    else
      test "override installation to tmp" do
        assert [env: [{"DENO_INSTALL", "/tmp"}], into: IO.stream()] ==
                 %{location: :tmp}
                 |> Config.new()
                 |> Config.format_install_options()
      end
    end

    test "override installation location" do
      assert [env: [{"DENO_INSTALL", "/tmp-location"}], into: IO.stream()] ==
               %{location: "/tmp-location"}
               |> Config.new()
               |> Config.format_install_options()
    end
  end
end
