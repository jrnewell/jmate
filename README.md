# Quick Directory

A productivity utility to quickly change directories mainly inspired by [working directory](https://github.com/karlin/working-directory) and other such history observing tools like [autojump](https://github.com/joelthelion/autojump) and [z](https://github.com/rupa/z).  It currently supports two modes: scheme and history.

## Installation

```bash
npm -g install quick-directory
```

This will install two commands `qd` and `hd`.

Next, you need to add the following command to the end of your `.bashrc`.  This creates bash functions, aliases, bash command completions and a wrapper around the `cd` function for history collecting.

```bash
eval "$(qd init)"
```

For faster shell loading time, you can cache the `init` output and source the cached file.

```bash
$ qd init cache

# in your .bashrc
source $HOME/.quick-dir/init.sh
```

## Scheme Mode

Scheme mode allows you to save directories by index number (slots) into a named "scheme".  You can create as many schemes as you wish and each scheme can have an unlimited number of slots.  The default scheme when you first start using quick directory is `default`.

Aliases are provided for quickly changing to a directory, setting a new directory entry, and listing all slots in the current directory

```
q  = change directory               (qd go)
qq = change directory interactively (qd pick)
ql = list directories               (qd list)
qs = set new entry                  (qd set)
```

All config options and schemes are stored in the directory `$HOME/.quick-dir`.  This can be changed by setting your `QDHOME` environment variable.

There are many `qd` commands to manage your schemes and slots.

```
  Usage: qd [options] [command]

  Commands:

    scheme [name]
       changes schemes (prints current scheme if no name is given)

    schemes
       lists all available schemes

    drop [name]
       drops a scheme (current scheme is used if no name is given)

    rename <name>
       renames current scheme to <name>

    list
       lists all slots for current scheme

    pick
       brings up a menu to choose a slot interactively

    get|go <idx>
       change to slot <idx> (you can also give text for a fuzzy search)

    rm [idx]
       remove slot <idx>

    swap <idx1> <idx2>
       swap the two slot numbers

    set [idx] [path]
       set slot [idx] to [path] (cwd is used if no path is given)
       (next highest slot number is used if no idx is given)

    setr [path]
       recursively set all the slots to child directories using the next
       highest slot numbers (cwd is used if no path is given)

    clear
       remove all slots from the current scheme

    compact
       reorder all slot numbers so there are no gaps

    init [cache]
       initalize your shell with aliases and functions

  Options:

    -h, --help     output usage information
    -V, --version  output the version number
  ```

## History Mode

History mode is similar to scheme mode except that slots are automatically filled with the last 10 visited directories.  This value is configurable in the json file in the `QDHOME` directory.

Currently, the history is automically logged by wrapping the `cd` function when sourcing the `init` command.  Similarly to scheme mode, history mode has preset aliases as well.

```
h  = change directory               (hd go)
hh = change directory interactively (hd pick)
hl = list history                   (hd list)
```

The `hd` command also provides some commands and options to manage your history

```
  Usage: hd [options] [command]

  Commands:

    add
       add entry to history (should be automatically called on cd)

    clear
       clear history

    list
       list history

    get|go <idx>
       change to a history item <idx> (you can also give text for a fuzzy search)

    pick
       brings up a menu to choose a history item interactively

  Options:

    -h, --help     output usage information
    -V, --version  output the version number
```

## Simple Example

```bash
$ cd /home/jrnewell/node.js/myproj
$ qd scheme myproj
$ qd setr
$ q html
# go to html folder

$ qq
# interactively choose folder

$ hl
# list my cd history

```

## Coming Soon

* Frecency or Top Mode
* Better interactive menu with fuzzy search
* Better support for other platforms

## License

[MIT License](http://en.wikipedia.org/wiki/MIT_License)
