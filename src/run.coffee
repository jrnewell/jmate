net       = require("net")
settings  = require("./settings")
send      = require("./send")
listen    = require("./listen")

# load settings
{options} = settings

# create TCP socket connection
tcp = net.connect options.port, options.host, () ->
  console.log "Connected to #{tcp.remoteAddress}:#{tcp.remotePort}" if options.verbose

  # first send our files
  send tcp, (err) ->
    return console.error "#{err}" if err?

    tcp.write(".\n")

    # now listen for changes
    listen tcp, (err) ->
      return console.error "#{err}" if err?

      console.log "Done" if options.verbose

tcp.on "error", (err) ->
  console.error "#{err}"
  process.exit(1)

tcp.on "end", () ->
  console.log "Connection closed" if options.verbose
