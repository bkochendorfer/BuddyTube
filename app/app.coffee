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

#Socket.io
usernames = {}
playlist = {}

io = require("socket.io").listen(app.listen(port))

io.sockets.on "connection", (socket) ->
  io.sockets.emit 'updateplaylist', playlist
  socket.emit "message",
    message: "Share your jams and chat about them"

  socket.on "chat", (data) ->
    io.sockets.emit 'updatechat', socket.username, data

  socket.on "adduser", (username) ->
    socket.username = username
    usernames[username] = username
    socket.emit 'updatechat', 'Playlist', 'you have connected'
    socket.broadcast.emit 'updatechat', 'Playlist', "#{username} has connected"
    io.sockets.emit 'updateusers', usernames

  socket.on "playlist", (song) ->
    id = getNameAndId song
    if (playlist[id] == undefined)
      playlist[id] = id
      socket.emit 'updatechat', 'Playlist', "You added #{id} to the playlist"
      socket.broadcast.emit 'updatechat', 'Playlist', "#{socket.username} added #{id} to the playlist"
      io.sockets.emit 'updateplaylist', playlist

  socket.on 'enque', () ->
    socket.emit 'enquefirstsong'

  socket.on "disconnect", () ->
    delete usernames[socket.username]
    io.sockets.emit 'updateusers', usernames
    socket.broadcast.emit 'updatechat', 'Playlist', socket.username + ' has disconnected'


console.log "listening on port " + port