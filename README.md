# jmate

A node.js port of [rmate](https://github.com/textmate/rmate).  Allows you to activate TextMate or Sublime Text through an ssh session.

## Installation

On server, install node.js and jmate.

```bash
npm -g install jmate
```

Configure ssh to tunnel to your local machine using a remote port

```
ssh -R 52698:localhost:52698 user@example.org
```

### Sublime Text

Install package [rsub](https://github.com/henrikpersson/rsub)

## Usage

```
jmate [options] file
````

You can also set default host and port options for jmate in `~/.jmate.rc` or using the environment variables `JMATE_HOST` and `JMATE_PORT` (rmate's vars and files work too).

## License

[MIT License](http://en.wikipedia.org/wiki/MIT_License)
