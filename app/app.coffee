express = require "express"
getYouTubeID = require "get-youtube-id"
youtube = require "youtube-feeds"
app = express()
port = 3000
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.engine "jade", require("jade").__express

app.get "/", (req, res) ->
  res.render "chatroom"

app.use express.static(__dirname + "/public")

#Manipulate data
getNameAndId = (song) ->
  id = getYouTubeID song
  # console.log "id is #{id}"
  # youtube.video(id, data)

  # console.log json
  # console.log "name is #{JSON.stringify(json)}"


usernames = {}
playlist = {}
master = ""

io = require("socket.io").listen(app.listen(port))

sockets = io.sockets

sockets.on "connection", (socket) ->

  sockets.emit 'updateplaylist', playlist

  socket.on "chat", updateChat

  socket.on "adduser", (username) ->
    socket.username = username
    if(Object.keys(usernames).length == 0)
      master = socket.id
      socket.master = true
    usernames[username] = username
    socket.emit 'updatechat', 'Playlist', 'you have connected'
    socket.broadcast.emit 'updatechat', 'Playlist', "#{username} has connected"
    sockets.emit 'updateusers', usernames

  socket.on "playlist", (song) ->
    id = getNameAndId song
    if (playlist[id] == undefined)
      playlist[id] = id
      socket.emit 'updatechat', 'Playlist', "You added #{id} to the playlist"
      socket.broadcast.emit 'updatechat', 'Playlist', "#{socket.username} added #{id} to the playlist"
      sockets.emit 'updateplaylist', playlist

  socket.on 'enque', () ->
    socket.emit 'enquefirstsong'

  socket.on 'sync', () ->
    if(socket.id != master)
      sockets.socket(master).emit("getcurrentsongdata");

  socket.on "mastersocketplayerdata", (id, time) ->
    socket.broadcast.emit 'syncallusers', id, time

  socket.on "disconnect", () ->
    delete usernames[socket.username]
    sockets.emit 'updateusers', usernames
    socket.broadcast.emit 'updatechat', 'Playlist', socket.username + ' has disconnected'

updateChat = (data) ->
  sockets.emit 'updatechat', @username, data





console.log "listening on port " + port