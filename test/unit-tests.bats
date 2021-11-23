#!/usr/bin/env bats
#
# Unit tests for prompt.gem
pg::style() { if [[ "$1" == -p ]]; then local p=p; shift; fi; local var=${2:-_pg_style}; printf -v "$var" "[${p}%s]" "$1"; }
pg::print() { if [[ "$1" == -p ]]; then local p=p; shift; fi; printf "[${p}%s]%s" "$@"; echo "[${p}OFF]"; }
pg::log() { echo "PGEM_LOG" "$@"; }
pg::decorate() { :; }
bc::cache() { :; }

source "$BATS_TEST_DIRNAME/../functions.sh"

expect_eq() {
  (( $# == 2 )) || { echo "Invalid inputs $*"; return 127; }
  if [[ "$1" != "$2" ]]; then
    printf "Actual:   '%s'\nExpected: '%s'\n" "${1//$'\e'/\\e}" "${2//$'\e'/\\e}"
    return 1
  fi
}

@test "tagsh" {
  _TITLE_PARTS=(foo 'bar  baz')
  expect_eq "$(prompt::_update_title)" $'\033]0;foo - bar  baz\a'
  expect_eq "$(tagsh tag; prompt::_update_title)" $'\033]0;foo - bar  baz - tag\a'
  _TITLE_PARTS[0]=foobar
  expect_eq "$(title_prefix=bump; prompt::_update_title)" $'\033]0;[bump] foobar - bar  baz\a'
}

@test "short_pwd" {
  HIDE_PATHS=('s|^/foo|F|' 's|/bar/|/BAR/|')

  expect_eq "$(PWD=/foo/bar/baz prompt::short_pwd)" "F/BAR/baz"
}

@test "_find_repo" {
   tmpdir=$(mktemp -d)
   mkdir -p "$tmpdir/foo/bar/baz"
   mkdir "$tmpdir/foo/marker"

   cd "$tmpdir/foo"
   expect_eq "$(prompt::_find_repo marker)" "$tmpdir/foo"
   cd "$tmpdir/foo/bar/baz"
   expect_eq "$(prompt::_find_repo marker)" "$tmpdir/foo"
   cd "$tmpdir"
   expect_eq "$(prompt::_find_repo marker)" ""
   ! prompt::_find_repo marker

   mkdir "$tmpdir/marker"
   cd "$tmpdir/foo/bar/baz"
   expect_eq "$(prompt::_find_repo marker)" "$tmpdir/foo"
}

@test "_format_seconds" {
  prompt::_format_seconds 10 || true
  expect_eq "$duration" "10s"
  prompt::_format_seconds 100 || true
  expect_eq "$duration" "1m 40s"
  prompt::_format_seconds 10000 || true
  expect_eq "$duration" "2h 46m 40s"
  prompt::_format_seconds 100000 || true
  expect_eq "$duration" "1d 3h 46m 40s"

  prompt::_format_seconds 1000000 another_var || true
  expect_eq "$another_var" "11d 13h 46m 40s"
}

# TODO add _prompt_command tests, possibly in a separate file

#
# env_functions
#

@test "hg_prompt" {
  type hg || skip

  # no repo
  cd "$(mktemp -d)"
  expect_eq "$(hg_prompt)" ""

  # new repo
  hg init
  expect_eq "$(hg_prompt)" '[pGREEN]default[pOFF]'

  # untracked file
  echo foo > foo.txt
  expect_eq "$(hg_prompt)" '[pPURPLE]default[pOFF]'

  # local mods
  hg addrem
  expect_eq "$(hg_prompt)" '[pLRED]default[pOFF]'

  # clean repo
  hg commit -m init -u foo
  expect_eq "$(hg_prompt)" '[pGREEN]default[pOFF]'

  # different branch
  hg branch foo
  expect_eq "$(hg_prompt)" '[pGREEN]foo[pOFF]'
}

@test "git_prompt" {
  type git || skip

  # no repo
  cd "$(mktemp -d)"
  expect_eq "$(git_prompt)" ""

  # new repo
  git init
  git config user.email foo@bar.baz
  git config user.name foo
  echo foo > foo.txt
  git add .
  expect_eq "$(git_prompt)" ""

  # first commit
  git commit -m "init"
  expect_eq "$(git_prompt)" '[pGREEN]master[pOFF]'

  # unstaged
  echo bar > foo.txt
  expect_eq "$(git_prompt)" '[pRED]master[pOFF]'

  # staged
  git add .
  expect_eq "$(git_prompt)" '[pYELLOW]master[pOFF]'

  # clean repo
  git commit -m "tweak file"
  expect_eq "$(git_prompt)" '[pGREEN]master[pOFF]'

  # untracked file
  touch bar.txt
  expect_eq "$(git_prompt)" '[pPURPLE]master[pOFF]'
}
