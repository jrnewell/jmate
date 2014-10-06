fs   = require("fs")
path = require("path")

Command = (name) ->
  @name = name
  @variable = {}
  @data = null
  @size = null

Command::setVar = (name, value) ->
  @variables[name] = value

Command::readFile = (file) ->
  return unless fs.existsSync file
  stat = fs.statSync file
  return unless stat.isFile() and stat.size?
  @size = stat.size
  @data = fs.readFileSync(file)

Command::readStdin = () ->
  readDone = false

  process.stdin.on "data", (data) =>
    @data += data

  process.stdin.on "end", () =>
    @size = @data.length
    readDone = true

module.exports = Command