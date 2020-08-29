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

@test "named colors" {
  expect_eq "$(color red)foo$(color)" '[RED]foo[OFF]'
  expect_eq "$(color green)foo$(color cyan)bar$(color none)" '[GREEN]foo[CYAN]bar[NONE]'
}

@test "numbered colors" {
  expect_eq "$(color 202)foo" '[202]foo'
  expect_eq "$(color '255;150;00')foo" '[255;150;00]foo'
}

@test "styles" {
  expect_eq "$(color red blink)foo" '[RED:BLINK]foo'
}

@test "pcolor" {
  expect_eq "$(pcolor yellow)foo$(pcolor)" '\[[YELLOW]\]foo\[[OFF]\]'
}

@test "logging utils" {
  expect_eq "$(note foo)" '[GREEN]NOTE:  [OFF]foo[OFF]'
  expect_eq "$(warn foo)" '[YELLOW]WARN:  [OFF]foo[OFF]'
  expect_eq "$(error foo)" '[RED]ERROR: [OFF]foo[OFF]'
}

@test "tagsh" {
  foo() { echo foo; }
  bar() { echo 'bar  baz'; }
  TITLE_INFO=(foo bar)

  expect_eq "$(tagsh)" $'\033]0;foo - bar  baz\007'
  expect_eq "$(tagsh tag)" $'\033]0;foo - bar  baz - tag\007'
  foo() { echo foobar; }
  expect_eq "$(tagsh)" $'\033]0;foobar - bar  baz\007'
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
  expect_eq "$(prompt::_format_seconds 10)" "10s"
  expect_eq "$(prompt::_format_seconds 100)" "1m 40s"
  expect_eq "$(prompt::_format_seconds 10000)" "2h 46m 40s"
  expect_eq "$(prompt::_format_seconds 100000)" "1d 3h 46m 40s"
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
