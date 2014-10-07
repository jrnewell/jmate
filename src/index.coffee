net       = require("net")
_         = require("lodash")
chalk     = require("chalk")
Settings  = require("./settings")
send      = require("./send")
listen    = require("./listen")

# load settings
settings = Settings()
{options, files} = settings

console.dir options

# create TCP socket connection
tcp = net.connect options.port, options.host, () ->
  console.log "connected to #{tcp.remoteAddress}:#{tcp.remotePort}" if options.verbose

  # first send our files
  send settings, tcp, (err) ->
    return console.error err if err?

    tcp.write(".\n")

    # now listen for changes
    listen settings, tcp, (err) ->
      return console.error err if err?

      console.log "done" if options.verbose
