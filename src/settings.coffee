fs        = require("fs")
path      = require("path")
os        = require("os")
commander = require("commander")
yaml      = require("js-yaml")

module.exports = retObj = {}

# make available throughout function
options = files = undefined

loadDiskSettings = () ->
  homePath = process.env[(if os.platform() is "win32" then "USERPROFILE" else "HOME")]
  file = path.join homePath, ".rmate.rc"
  return unless fs.existsSync file

  # rmate uses YAML instead of json
  try
    params = yaml.safeLoad(fs.readFileSync(file, "utf8"))
    options.host = params.host if params.host?
    options.port = params.port if params.port?
  catch ex
    console.error ex

loadSettings = () ->
  retObj.options = options =
    host: "localhost"
    port: 52699
    wait: false
    force: false
    verbose: false
    lines: []
    names: []
    types: []

  loadDiskSettings()

  options.host = process.env.RMATE_HOME if process.env.RMATE_HOME?
  options.port = process.env.RMATE_PORT if process.env.RMATE_PORT?

loadSettings()

commander
  .version(require("../package.json").version)
  .option("-h, --host <str>", "Connect to host. Use 'auto' to detect the host from SSH. Defaults to '#{options.host}'.")
  .option("-p, --port <num>", "Port number to use for connection. Defaults to #{options.port}.", parseInt)
  .option("-w, --wait", "Wait for file to be closed by editor.")
  .option("-l, --line <num>", "Place caret on line <num> after loading file.", parseInt)
  .option("-n, --name <str>", "The display name shown in editor.")
  .option("-t, --type <str>", "Treat file as having type <str>.")
  .option("-f, --force", "Open even if the file is not writable.")
  .option("-v, --verbose", "Verbose logging messages.")

commander.parse(process.argv)

options.host = commander.host if commander.host?
options.port = commander.port if commander.port?
options.wait = commander.wait if commander.wait?
options.lines.push commander.line if commander.line?
options.names.push commander.name if commander.name?
options.types.push commander.type if commander.type?
options.force = commander.force if commander.force?
options.verbose = commander.verbose if commander.verbose?

# parse ssh connection
if options.host is "auto"
  options.host = (if process.env.SSH_CONNECTION? then process.env.SSH_CONNECTION.split(" ")[0] else "localhost")

retObj.fileIsWritable = fileIsWritable = (file) ->
  try
    fd = fs.openSync(file, "a")
    fs.closeSync(fd)
    return true
  catch ex
    return false

fatalErr = (msg) ->
  console.error msg
  process.exit(1)

retObj.files = files = commander.args[..]
files.push "-" if files.length == 0 and (not process.stdin.isTTY or options.wait)
for file, idx in files
  if file is "-"
    console.error "Reading from stdin, press ^D to stop" if process.stdin.isTTY
  else if fs.existsSync file
    stat = fs.statSync file
    fatalErr "#{file} is a directory. aborting..." if stat.isDirectory()
    unless fileIsWritable(file)
      if options.force
        console.error "file #{file} is not writable.  Opening anyway." if options.verbose
      else
        fatalErr "file #{file} is not writable.  Use -f/--force to open anyway"

