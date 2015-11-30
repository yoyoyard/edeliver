#!/bin/bash
set -e
ELIXIR_VERSION=1.1.1
OTP_VERSION=18.1
ORIGIN_DIR="$(dirname $(cd $(dirname "$0") && pwd))"
MIX_TEST_PROJECT_NAME="edeliver_mix_test"
FIRST_RELEASE_VERSION="0.0.1"
__log() {
  :
}
source "${ORIGIN_DIR}/libexec/output"
cd "${ORIGIN_DIR}/test"

__patch_mixfile() {
  local _line
  status "Patching mixfile"
  while IFS='' read -r _line || [[ -n "$_line" ]]; do
    echo "$_line"
    [[ $_in_deps == "true" ]] && echo "# ! in deps"
    if [[ "$_line" =~ defp?[[:space:]]+deps ]]; then
      while [[ ! "$_line" =~ ^\s*end\s*$ ]]; do read -r _line; done
      echo "   [
      {:exrm, github: \"bitwalker/exrm\", override: true},
      {:edeliver, path: \"$ORIGIN_DIR\"},
   ]
  end"
    elif [[ "$_line" =~ defp?[[:space:]]+application ]]; then
      while [[ ! "$_line" =~ ^\s*end\s*$ ]]; do read -r _line; done
      echo "   [
     applications: [:logger, :edeliver],
     mod: {EdeliverMixTest, []}
   ]
  end"
    fi
  done < mix.exs > mix.exs.deps && mv mix.exs.deps mix.exs
}

__create_mix_project() {
  status "Creating mix test project"
  echo "Y" | mix new "$MIX_TEST_PROJECT_NAME" --sup --force
}

__create_mix_project
cd "$MIX_TEST_PROJECT_NAME"
__patch_mixfile
echo $ELIXIR_VERSION > .exenv-version
echo $OTP_VERSION > .erlang-release
mix do deps.get, release

status "Checking whether release package was built"
GENERATED_RELEASE_FILE="rel/${MIX_TEST_PROJECT_NAME}/releases/${FIRST_RELEASE_VERSION}/${MIX_TEST_PROJECT_NAME}.tar.gz"
[[ -f "$GENERATED_RELEASE_FILE" ]] && success_message "${MIX_TEST_PROJECT_NAME}.tar.gz exists"