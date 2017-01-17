# Prompt.gem

*See the [ProfileGem](https://bitbucket.org/dimo414/profilegem) project for installation
instructions.*

This gem configures your terminal prompt to a simple but extensible format that
is easy to read and informative.

The prompt generally looks like so:

    [LAST_EXIT_CODE] [USERNAME@HOST:PWD ADDITIONAL_INFO]
    $ 

e.g.

    [0] [user@hostname:~/ProfileGem/prompt.gem]
    $ 

## Features

* Blank line before each prompt, and `$` on its own line makes it easy to visually distinguish
  one command from the next.
* Tracks the duration of commands and displays the duration of long-running (>5s) commands.
* Also updates the terminal's title, and provides the `tagsh` command to label the window.
* Provides `color` and `pcolor` functions to easily colorize your prompt and commands.
* Comes with several optional helper functions you can enable to add additional functionality
  to your prompt, such as the status of your current Mercurial or Git repo. See
  [`env_functions.sh`](https://bitbucket.org/dimo414/prompt.gem/src/tip/env_functions.sh)
  for a collection of functions bundled with this gem.
* Also supports triggering callbacks when the prompt is rendered, enabling
  out-of-band functionality (e.g. desktop notifications). See
  [`callback_functions.sh`](https://bitbucket.org/dimo414/prompt.gem/src/tip/callback_functions.sh)
  for callbacks bundled with this gem you can enable immediately.

## Customizations

Set or update these values in your `local.conf.sh` in order to further customize your prompt. Gems
that integrate with prompt.gem can also update these variables in their `environment.sh`.

See [`base.conf.sh`](https://bitbucket.org/dimo414/prompt.gem/src/tip/base.conf.sh) for all
availible customizations.

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
* `COMMAND_FINISHED_CALLBACKS`: an array of commands to be called during prompt generation and
  passed information about the previous command, including exit code and runtime.

## Warning

This gem takes advantage of
[Bash's `DEBUG` trap](http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html) in order to
record how long commands take, overriding any previous trap you may have installed. In most cases
this should cause no issues, but if other parts of your environment start behaving strangely you
may need to disable this functionality because they expect *their* trap to be running.

Set `CAPTURE_COMMAND_TIMES=false` in your `local.conf.sh` to do so.