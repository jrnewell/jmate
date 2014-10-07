fs        = require("fs")
path      = require("path")
_         = require("lodash")
chalk     = require("chalk")
async     = require("async")

module.exports = (settings, tcp) ->
  {options, files} = settings

  # tcp.on 'data', (data) ->

  # tcp.on 'end', () ->
  #   tcp.end()
  #   console.log "done" if options.verbose

  # tcp.on 'error', (err) ->
  #   console.error err