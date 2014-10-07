settings = require("./settings")

# load settings
{options} = settings

if options.wait
  require("./run")
else
  spawn = require("child_process").spawn
  child_args = ["./lib/run.js"].concat process.argv[2..]
  child = spawn "node", child_args,
    stdio: "inherit"
    detached: true
  child.unref()

  child.on "error", (err) ->
    console.error "#{err}"
    process.exit(1)
