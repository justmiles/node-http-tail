#!/usr/bin/env coffee
pm2 = require 'pm2'
app_package = require "#{__dirname}/../package.json"
open = require('open')
fs = require 'fs'
async = require 'async'

port = 3000
host = process.env.HOSTNAME? or '127.0.0.1'

app =
  name: app_package.name
  script: "index.js"
  exec_mode: 'fork'
  watch: false
  merge_logs: true
  log_date_format: "YYYY-MM-DD HH:mm Z"
  instances: 1
  max_memory_restart: '256M'

parameters = process.argv.map (arg,next)->
  if arg.match /-\S/
    switch arg
      when '-v'
        console.log app_package.version

class Controller
  start: (cb)->
    pm2.connect ->

      pm2.describe app_package.name, (err, proc) ->
        i = 0; len = proc.length
        while i < len
          p = proc[i]
          if p.name == app_package.name and p.pid != 0
            found = true
            console.log "#{app_package.name} is already running on #{host}, process #{p.pid}."
          i++
        if !found
          pm2.start app, (err, apps) ->
            if err != null
              console.log err.msg
            else
              console.log app_package.name + ' running'
            cb pm2.disconnect()
        else
          cb pm2.disconnect()

  openfile: (file)->
   open("http://#{host}:#{port}#{file}")

control = new Controller



return control.start() unless process.argv[2]?

switch process.argv[2]

  when 'stop'
    return pm2.connect ->
      pm2.stop app_package.name, (err, proc) ->
        if err != null
          console.log err.msg
        else
          console.log app_package.name + ' stopped'
        pm2.disconnect()


async.series [
  control.start

  (cb)->

    file = "#{process.cwd()}/#{process.argv[2]}"
    if fs.existsSync file
      cb control.openfile(file)

]


#
#switch process.argv[2]
#
#  when 'stop'
#    pm2.connect ->
#      pm2.stop app_package.name, (err, proc) ->
#        if err != null
#          console.log err.msg
#        else
#          console.log app_package.name + ' stopped'
#        pm2.disconnect()
#
#  when 'restart'
#    pm2.connect ->
#      pm2.stop app_package.name, (err, proc) ->
#        if err != null
#          console.log err.msg
#        else
#          console.log app_package.name + ' stopped'
#          pm2.start app, (err, apps) ->
#            if err != null
#              console.log err.msg
#            else
#              console.log app_package.name + ' started'
#            pm2.disconnect()
#
#  when 'status'
#    pm2.connect ->
#      return pm2.describe app_package.name, (err, proc) ->
#        i = 0; len = proc.length
#        while i < len
#          p = proc[i]
#          if p.name == app_package.name and p.pid != 0
#            found = true
#            console.log "#{app_package.name} is running on #{process.env.HOSTNAME}, process #{p.pid}."
#          i++
#        if !found
#          console.log "#{app_package.name} is not running"
#        pm2.disconnect()
#
#  else
#    console.log("Usage: #{app_package.name} (start|stop|status|restart)")
