# Prompt.gem

*See the [ProfileGem](https://github.com/dimo414/ProfileGem) project for installation
instructions.*

This gem configures your terminal prompt to a simple but extensible format that
is easy to read and informative.

The prompt generally looks like so:

    [LAST_EXIT_CODE] [USERNAME@HOST:PWD ADDITIONAL_INFO]
    $

e.g.

![Screenshot of basic prompt functionality](/example.png)

## Features

* Blank line before each prompt, and `$` on its own line makes it easy to visually distinguish
  one command from the next.
* Tracks the duration of commands and displays the duration of long-running (>5s) commands.
* Also updates the terminal's title, and provides the `tagsh` command to label the window.
* Provides `color` and `pcolor` functions to easily colorize your prompt and commands.
* Comes with several optional helper functions you can enable to add additional functionality
  to your prompt, such as the status of your current Mercurial or Git repo. See
  [`env_functions.sh`](https://github.com/dimo414/prompt.gem/blob/master/env_functions.sh)
  for a collection of functions bundled with this gem.
* Also supports triggering callbacks when the prompt is rendered, enabling
  out-of-band functionality (e.g. desktop notifications). See
  [`callback_functions.sh`](https://github.com/dimo414/prompt.gem/blob/master/callback_functions.sh)
  for callbacks bundled with this gem you can enable immediately.

## Customizations

Set or update these values in your `local.conf.sh` in order to further customize your prompt. Gems
that integrate with prompt.gem can also update these variables in their `environment.sh`.

See [`base.conf.sh`](https://github.com/dimo414/prompt.gem/blob/master/base.conf.sh) for all
available customizations.

* `HOST_COLOR`: sets the color of the `hostname`; useful for visually distinguishing different
  hosts you work with regularly.
* `HIDE_PATHS`: an array of sed expressions that are applied to the `PWD` before printing it.
  This way you can specify custom shorthand for directories you spend a lot of time in. For
  example if you're often working in `/home/username/workspace/importantproject` you could add the
  pattern `"s|^${HOME}/workspace/importantproject|IP|"` to shorten the `PWD` in your prompt to
  `IP/some/subdirectory`.
* `ENV_INFO`: an array of commands to execute, whose output will be included in the prompt after
  the `PWD`. This lets you display whatever extra information you might want without fiddling with
  the prompt itself.
* `TITLE_INFO`: like `ENV_INFO`, an array of commands whose output will make up the window title.
* `COMMAND_FINISHED_CALLBACKS`: an array of commands to be called during prompt generation and
  passed information about the previous command, including exit code and runtime.

## Interoperability Warning

This gem overrides your `PS1` prompt along with the `PROMPT_COMMAND` function. This is by design
and cannot be disabled. You can however register callbacks that are invoked by the `PROMPT_COMMAND`
function by adding your function(s) to the `COMMAND_FINISHED_CALLBACKS` array.

This gem also optionally takes advantage of
[Bash's `DEBUG` trap](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html) in order to
record how long commands take, overriding any previous trap you may have installed. In most cases
this should cause no issues, but if other parts of your environment start behaving strangely you
may need to disable this functionality because they expect *their* trap to be running.

Set `OWN_DEBUG_TRAP=false` in your `local.conf.sh` to do so.

## Copyright and License

Copyright 2015-2017 Michael Diamond

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
