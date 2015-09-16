Tail = require 'always-tail'
fs = require 'fs'
http = require 'http'
express = require 'express'
path = require 'path'


port = 3000
host = process.env.HOSTNAME? or '127.0.0.1'


app = module.exports.app = express()
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade' 
app.use express.static(__dirname + '/web')

server = http.createServer(app)

io = require('socket.io').listen(server)

clients = {}
io.on 'disconnect', (socket)->
  console.log clients
  console.log 'client disconnected'
  delete clients[socket.id]

app.get '*', (req, res) ->
  filepath = req.path
  return console.log('no') unless filepath?
  if fs.existsSync filepath

    file = path.basename filepath
    console.log file
    res.render 'index',
      title: file
      filepath: filepath
      file: file

    customTail = new Tail filepath, '\n', interval: 1000

    customTail.on 'line', (data) ->
      io.emit file, data

    console.log filepath
    io.on 'connection', (socket)->
      console.log 'got new connection'
      socket.emit file,
        fs.readFileSync(filepath).toString()
        id: socket.id

  else
  	return res.render 'error',
	    title: 'File Not Found'
	    error: "Sorry! Could not find: #{req.path}"

server.listen port
console.log "http://#{host}:#{port}"
