#! /bin/bash
set -e

source "/root/.asdf/asdf.sh"

asdf info

mix test
mix deno.install
deno --version
