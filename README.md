# jmate

A node.js port of [rmate](https://github.com/textmate/rmate).  Allows you to remote edit files in TextMate or Sublime Text through an ssh session.

## Installation

On server, install node.js and jmate.

```bash
npm -g install jmate
```

Configure ssh to tunnel to your local machine using a remote port

```
ssh -R 52698:localhost:52698 user@example.com
```

Or, put this in your ~/.ssh/config to enable remote forwarding for your server(s):

```
Host example.com
    RemoteForward 52698 127.0.0.1:52698
```

### Sublime Text

Install package [rsub](https://github.com/henrikpersson/rsub)

## Usage

```
Usage: jmate [options] <file ...>

  Options:

    -h, --help        output usage information
    -V, --version     output the version number
    -h, --host <str>  Connect to host. Use 'auto' to detect the host from SSH. Defaults to 'localhost'.
    -p, --port <num>  Port number to use for connection. Defaults to 52698.
    -w, --wait        Wait for file to be closed by editor.
    -l, --line <num>  Place caret on line <num> after loading file.
    -n, --name <str>  The display name shown in editor.
    -t, --type <str>  Treat file as having type <str>.
    -f, --force       Open even if the file is not writable.
    -v, --verbose     Verbose logging messages.
```

You can also set default host and port options for jmate in `/etc/jmate.rc` or `~/.jmate.rc`.  Additionally, the environment variables `JMATE_HOST` and `JMATE_PORT` will set the host and port options as well. For backwards compatibility, `rmate.rc` and `RMATE_` can alternatively be used.

## License

[MIT License](http://en.wikipedia.org/wiki/MIT_License)
