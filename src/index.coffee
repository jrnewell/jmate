fs        = require("fs")
path      = require("path")
os        = require("os")
net       = require("net")
_         = require("lodash")
commander = require("commander")
chalk     = require("chalk")
yaml      = require("js-yaml")

# make available throughout file
settings = files = tcp = undefined

loadDiskSettings = () ->
  homePath = process.env[(if os.platform() is "win32" then "USERPROFILE" else "HOME")]
  file = path.join homePath, ".rmate.rc"
  return unless fs.existsSync file

  # rmate uses YAML instead of json
  try
    params = yaml.safeLoad(fs.readFileSync(file, "utf8"))
    settings.host = params.host if params.host?
    settings.port = params.port if params.port?
  catch ex
    console.error ex

loadSettings = () ->
  settings =
    host: "localhost"
    port: 52698
    wait: false
    force: false
    verbose: false
    lines: []
    names: []
    types: []

  loadDiskSettings()

  settings.host = process.env.RMATE_HOME if process.env.RMATE_HOME?
  settings.port = process.env.RMATE_PORT if process.env.RMATE_PORT?

loadSettings()

commander
  .version(require("../package.json").version)
  .option("-h, --host <str>", "Connect to host. Use 'auto' to detect the host from SSH. Defaults to '#{settings.host}'.")
  .option("-p, --port <num>", "Port number to use for connection. Defaults to #{settings.port}.", parseInt)
  .option("-w, --wait", "Wait for file to be closed by editor.")
  .option("-l, --line <num>", "Place caret on line <num> after loading file.", parseInt)
  .option("-n, --name <str>", "The display name shown in editor.")
  .option("-t, --type <str>", "Treat file as having type <str>.")
  .option("-f, --force", "Open even if the file is not writable.")
  .option("-v, --verbose", "Verbose logging messages.")

commander.parse(process.argv)

settings.host = commander.host if commander.host?
settings.port = commander.port if commander.port?
settings.wait = commander.wait if commander.wait?
settings.lines.push commander.line if commander.line?
settings.names.push commander.name if commander.name?
settings.types.push commander.type if commander.type?
settings.force = commander.force if commander.force?
settings.verbose = commander.wait if commander.verbose?

# parse ssh connection
if settings.host is "auto"
  settings.host = (if process.env.SSH_CONNECTION? then process.env.SSH_CONNECTION.split(" ")[0] else "localhost")

fileIsWritable = (file) ->
  try
    return true unless fs.existsSync file
    fd = fs.openSync(file, "a")
    fs.closeSync(fd)
    return true
  catch ex
    return false

sendOpenFile = (file, idx, callback) ->
  tcp.write("open\n")

  writeVar = (name, val) ->
    tcp.write("#{name}: #{val}")

  if settings.names.length > idx
    writeVar "display-name", settings.name[idx]
  else if file is "-"
    writeVar "display-name", "#{tcp.localAddress}:untitled (stdin)"
  else
    writeVar "display-name", "#{tcp.localAddress}:#{file}"

  writeVar "real-path", path.resolve(file) unless file is "-"
  writeVar "data-on-save", "yes"
  writeVar "re-activate", "yes"
  writeVar "token", file
  writeVar "selection", settings.lines[idx] if settings.lines.length > idx
  writeVar "file-type", "txt" if path is "-"
  writeVar "file-type", settings.types[idx] if settings.types.length > idx




files = commander.args[:]
files.push "-" if files.length == 0 and (not process.stdin.isTTY or settings.wait)
for file, idx in files
  if file is "-"
    console.error "Reading from stdin, press ^D to stop" if process.stdin.isTTY
  else if fs.existsSync file
    stat = fs.statSync file
    console.error "#{file} is a directory. aborting..." if stat.isDirectory()
    unless fileIsWritable(file)
      if settings.force
        console.error "file #{file} is not writable.  Opening anyway." if settings.verbose
      else
        console.error "file #{file} is not writable.  Use -f/--force to open anyway"

tcp = net.connect settings.port, settings.host, () ->
  console.log "connected to #{tcp.remoteAddress}:#{tcp.remotePort}" if settings.verbose

  tcp.on 'data', (data) ->

  tcp.on 'end', () ->
    tcp.end()
    console.log "done" if settings.verbose

  tcp.on 'error', (err) ->
    console.error err



