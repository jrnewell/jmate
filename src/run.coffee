net       = require("net")
async     = require("async")
settings  = require("./settings")
send      = require("./send")
listen    = require("./listen")

# load settings
{options} = settings

# create TCP socket connection
tcp = net.connect options.port, options.host, () ->
  console.log "Connected to #{tcp.remoteAddress}:#{tcp.remotePort}" if options.verbose

  async.series [
    (callback) -> send tcp, callback
    (callback) -> tcp.write(".\n", callback)
    (callback) -> listen tcp, callback
  ], (err, results) ->
     return console.error "#{err}" if err?
     console.log "Done" if options.verbose

tcp.on "error", (err) ->
  console.error "#{err}"
  process.exit(1)

tcp.on "end", () ->
  console.log "Connection closed" if options.verbose
