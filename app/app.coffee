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

usernames = {}
playlist = {}
master = ""

io = require("socket.io").listen(app.listen(port))

sockets = io.sockets

sockets.on "connection", (socket) ->

  sockets.emit 'updateplaylist', playlist

  socket.on "chat",     updateChat
  socket.on "adduser",  addUser
  socket.on "playlist", addSong
  socket.on "enque",    enqueFirstSong
  socket.on "sync",     syncPlayback

  socket.on "mastersocketplayerdata", (id, time) ->
    socket.broadcast.emit 'syncallusers', id, time

  socket.on "disconnect", () ->
    delete usernames[socket.username]
    sockets.emit 'updateusers', usernames
    socket.broadcast.emit 'updatechat', 'Playlist', socket.username + ' has disconnected'

updateChat = (data) ->
  sockets.emit 'updatechat', @username, data

setMaster = (socket) ->
  master = socket.id
  socket.master = true

isFirstUser = ->
  Object.keys(usernames).length == 0

addUser = (username) ->
  @username = username
  setMaster(this) if isFirstUser()
  usernames[username] = username

  @emit 'updatechat', 'Playlist', 'you have connected'
  @broadcast.emit 'updatechat', 'Playlist', "#{username} has connected"
  sockets.emit 'updateusers', usernames

addSong = (song) ->
  id = getYouTubeID(song)
  if (playlist[id] == undefined)
    playlist[id] = id
    @emit 'updatechat', 'Playlist', "You added #{id} to the playlist"
    @broadcast.emit 'updatechat', 'Playlist', "#{@username} added #{id} to the playlist"
    sockets.emit 'updateplaylist', playlist

enqueFirstSong = ->
  @emit 'enquefirstsong'

syncPlayback = ->
  if @id != master
    sockets.socket(master).emit("getcurrentsongdata")

console.log "listening on port " + port
