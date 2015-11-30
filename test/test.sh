#!/bin/bash
set -e
ELIXIR_VERSION=1.1.1
OTP_VERSION=18.1
ORIGIN_DIR="$(dirname $(cd $(dirname "$0") && pwd))"
MIX_TEST_PROJECT_NAME="edeliver_mix_test"
FIRST_RELEASE_VERSION="0.0.1"
TEST_PAGE_TITLE="hello world"
TEST_PAGE_BODY="edeliver_mix_test $FIRST_RELEASE_VERSION"

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
    if [[ "$_line" =~ defp?[[:space:]]+deps ]]; then
      while [[ ! "$_line" =~ ^\s*end\s*$ ]]; do read -r _line; done
      echo "   [
      {:exrm, github: \"bitwalker/exrm\", override: true},
      {:edeliver, path: \"$ORIGIN_DIR\"},
      {:postgrex, \">= 0.0.0\"},
      {:ecto, github: \"elixir-lang/ecto\"},
      {:phoenix_generator, github: \"etufe/phoenix_generator\"}
   ]
  end"
    elif [[ "$_line" =~ defp?[[:space:]]+application ]]; then
      while [[ ! "$_line" =~ ^\s*end\s*$ ]]; do read -r _line; done
      echo "   [
     applications: [:logger, :edeliver, :ecto, :postgrex, :phoenix_generator],
     mod: {EdeliverMixTest, []}
   ]
  end"
    fi
  done < mix.exs > mix.exs.deps && mv mix.exs.deps mix.exs
}

__add_repo_to_app_supervisor() {
  local _line
  status "Adding repository to application supervisor"
  while IFS='' read -r _line || [[ -n "$_line" ]]; do
    echo "$_line"
    if [[ "$_line" =~ ^[[:space:]]*children[[:space:]]+= ]]; then
      while [[ ! "$_line" =~ ^\s*\]\s*$ ]]; do read -r _line; done
      echo "      worker(EdeliverMixTest.Repo, []),
    ]"
    fi
  done < lib/${MIX_TEST_PROJECT_NAME}.ex > lib/${MIX_TEST_PROJECT_NAME}.ex.sup && mv lib/${MIX_TEST_PROJECT_NAME}.ex.sup lib/${MIX_TEST_PROJECT_NAME}.ex
}

__create_mix_project() {
  status "Creating mix test project"
  echo -n Y | mix new "$MIX_TEST_PROJECT_NAME" --sup --force
}

__get_deps() {
  status "Getting dependencies"
  echo $ELIXIR_VERSION > .exenv-version
  echo $OTP_VERSION > .erlang-release
  mix do deps.get, deps.compile
}


__create_phoenix_project() {
  status "Creating phoenix project"
  status "Creating dummy config"
  echo -n n | mix phoenix.gen.jumpstart
  status "Creating router"
  mkdir -p web
  > web/router.ex cat <<eot
defmodule EdeliverMixTest.Router do
  use Phoenix.Router
  pipe_through :browser do
  end
  scope "/", EdeliverMixTest do
  end
end
eot
  status "Creating test page"
  echo -n Y | mix phoenix.gen.scaffold note "$TEST_PAGE_TITLE" "$TEST_PAGE_BODY"
}

__create_mix_project
cd "$MIX_TEST_PROJECT_NAME"
__patch_mixfile
__get_deps
__create_phoenix_project
__add_repo_to_app_supervisor
mix release
status "Checking whether release package was built"
GENERATED_RELEASE_FILE="rel/${MIX_TEST_PROJECT_NAME}/releases/${FIRST_RELEASE_VERSION}/${MIX_TEST_PROJECT_NAME}.tar.gz"
[[ -f "$GENERATED_RELEASE_FILE" ]] && success_message "${MIX_TEST_PROJECT_NAME}.tar.gz exists" || error "No release file was generated"
