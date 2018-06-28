#!/usr/bin/env bats
#
# Unit tests for prompt.gem

pg::log() { echo "PGEM_LOG" "$@"; }
pg::decorate() { :; }
bc::cache() { :; }

source "$BATS_TEST_DIRNAME/../functions.sh"

expect_eq() {
  (( $# == 2 )) || { echo "Invalid inputs $*"; return 127; }
  if [[ "$1" != "$2" ]]; then
    echo "Actual:   '$1'"
    echo "Expected: '$2'"
    return 1
  fi
}

_raw() { sed -e 's/\o33/\\033/g' -e 's/\o07/\\007/g'; }
color_raw() { color "$@" | _raw; }

@test "named colors" {
  expect_eq "$(color_raw red)foo$(color_raw)" "\033[31mfoo\033[0m"
  expect_eq "$(color_raw green)foo$(color_raw cyan)bar$(color_raw none)" "\033[32mfoo\033[36mbar\033[0m"
}

@test "numbered colors" {
  expect_eq "$(color_raw 202)foo" "\033[38;5;202mfoo"
  expect_eq "$(color_raw '255;150;00')foo" "\033[38;2;255;150;00mfoo"
}

@test "styles" {
  expect_eq "$(color_raw red blink)foo" "\033[5;31mfoo"
}

@test "pcolor" {
  pcolor_raw() { pcolor "$@" | _raw; }
  expect_eq "$(pcolor_raw yellow)foo$(pcolor_raw)" "\[\033[33m\]foo\[\033[0m\]"
}

@test "logging utils" {
  expect_eq "$(note foo | _raw)" "\033[32mNOTE:\033[0m  foo"
  expect_eq "$(warn foo | _raw)" "\033[33mWARN:\033[0m  foo"
  expect_eq "$(error foo | _raw)" "\033[31mERROR:\033[0m foo"
}

@test "tagsh" {
  tagsh_raw() { tagsh "$@" | _raw; }
  foo() { echo foo; }
  bar() { echo 'bar  baz'; }
  TITLE_INFO=(foo bar)

  expect_eq "$(tagsh_raw)" "\033]0;foo - bar  baz\007"
  expect_eq "$(tagsh_raw tag)" "\033]0;foo - bar  baz - tag\007"
  foo() { echo foobar; }
  expect_eq "$(tagsh_raw)" "\033]0;foobar - bar  baz\007"
}

@test "short_pwd" {
  pwd() { echo /foo/bar/baz; }
  HIDE_PATHS=('s|^/foo|F|' 's|/bar/|/BAR/|')

  expect_eq "$(short_pwd)" "F/BAR/baz"
}

@test "_find_repo" {
   tmpdir=$(mktemp -d)
   mkdir -p "$tmpdir/foo/bar/baz"
   mkdir "$tmpdir/foo/marker"

   cd "$tmpdir/foo"
   expect_eq "$(_find_repo marker)" "$tmpdir/foo"
   cd "$tmpdir/foo/bar/baz"
   expect_eq "$(_find_repo marker)" "$tmpdir/foo"
   cd "$tmpdir"
   expect_eq "$(_find_repo marker)" ""
   ! _find_repo marker

   mkdir "$tmpdir/marker"
   cd "$tmpdir/foo/bar/baz"
   expect_eq "$(_find_repo marker)" "$tmpdir/foo"
}

@test "_format_seconds" {
  expect_eq "$(_format_seconds 10)" "10s"
  expect_eq "$(_format_seconds 100)" "1m 40s"
  expect_eq "$(_format_seconds 10000)" "2h 46m 40s"
  expect_eq "$(_format_seconds 100000)" "1d 3h 46m 40s"
}

# TODO add _prompt_command tests, possibly in a separate file

#
# env_functions
#

@test "hg_prompt" {
  type hg || skip
  hg_prompt_raw() { hg_prompt "$@" | _raw; }

  # no repo
  cd $(mktemp -d)
  expect_eq "$(hg_prompt_raw)" ""

  # new repo
  hg init
  expect_eq "$(hg_prompt_raw)" "\[\033[32m\]default\[\033[0m\]"

  # untracked file
  echo foo > foo.txt
  expect_eq "$(hg_prompt_raw)" "\[\033[35m\]default\[\033[0m\]"

  # local mods
  hg addrem
  expect_eq "$(hg_prompt_raw)" "\[\033[91m\]default\[\033[0m\]"

  # clean repo
  hg commit -m init -u foo
  expect_eq "$(hg_prompt_raw)" "\[\033[32m\]default\[\033[0m\]"

  # different branch
  hg branch foo
  expect_eq "$(hg_prompt_raw)" "\[\033[32m\]foo\[\033[0m\]"
}

@test "git_prompt" {
  type git || skip
  git_prompt_raw() { git_prompt "$@" | _raw; }

  # no repo
  cd $(mktemp -d)
  expect_eq "$(git_prompt_raw)" ""

  # new repo
  git init
  git config user.email foo@bar.baz
  git config user.name foo
  echo foo > foo.txt
  git add .
  expect_eq "$(git_prompt_raw)" ""

  # first commit
  git commit -m "init"
  expect_eq "$(git_prompt_raw)" "\[\033[32m\]master\[\033[0m\]"

  # unstaged
  echo bar > foo.txt
  expect_eq "$(git_prompt_raw)" "\[\033[31m\]master\[\033[0m\]"

  # staged
  git add .
  expect_eq "$(git_prompt_raw)" "\[\033[33m\]master\[\033[0m\]"

  # clean repo
  git commit -m "tweak file"
  expect_eq "$(git_prompt_raw)" "\[\033[32m\]master\[\033[0m\]"

  # untracked file
  touch bar.txt
  expect_eq "$(git_prompt_raw)" "\[\033[35m\]master\[\033[0m\]"
}
