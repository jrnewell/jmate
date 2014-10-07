net = require("net")

port = 52699

server = net.createServer (conn) ->
  console.log "connection opened"

  conn.on "data", (data) ->
    console.log data.toString("utf8")

  conn.on "error", (err) ->
    console.error err

  conn.on "end", () ->
    console.log "connenction ended"

server.listen port, "127.0.0.1", (err) ->
  return console.error err if err?
  console.log "server listening on #{port}"
