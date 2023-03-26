Application.put_env(:deno_installer, :system, DenoInstaller.System.Mock)
ExUnit.start()
