# Prompt.gem

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

## Customizations

Set or update these values in your `local.conf.sh` or in other gems in order to further customize
your prompt. See `base.conf.sh` for all availible customizations.

* `HOST_COLOR`: sets the color of the `hostname`; useful for visually distinguishing different
  hosts you work with regularly.
* `HIDE_PATHS`: an array of sed expressions that are applied to the `PWD` before printing it.
  This way you can specify custom shorthand for directories you spend a lot of time in. For
  example if you're often working in `/home/username/workspace/importantproject` you could add the
  pattern `"s|^${HOME}/workspace/importantproject|IP|"` to shorten the `PWD` in your prompt to
  `IP/some/subdirectory`.
* `ENV_INFO`: an array of commands to execute, whos output will be included in the prompt after the
  `PWD`. This lets you display whatever extra information you might want in your prompt, without
  fiddling with the prompt itself. Generally this will be functions defined in other gems and
  added to `ENV_INFO` in their `environment.sh`.

  See the `env_functions.sh` file for some useful functions to add to this array out of the box.

