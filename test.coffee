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

  closePart2 = () ->
    text = "\n"
    conn.write text

  closePart1 = () ->
    text = "close\ntoken: testfile.txt\n"
    conn.write text
    setTimeout closePart2, 500

  conn.write "Test Editor\n"
  setTimeout closePart1, 500

server.listen port, "127.0.0.1", (err) ->
  return console.error err if err?
  console.log "server listening on #{port}"
