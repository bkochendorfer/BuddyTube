express = require 'express'
getYouTubeID = require 'get-youtube-id'
youtube = require 'youtube-feeds'
app = express()
port = 3000
app.set 'views', "#{ __dirname  }/views"
app.set 'view engine', 'jade'
app.engine 'jade', require('jade').__express

app.get '/', (req, res) ->
  res.render 'chatroom'

app.use express.static("#{ __dirname }/public")

usernames = {}
playlist = {}
master = ''

io = require('socket.io').listen(app.listen(port))

io.sockets.on 'connection', (socket) -> new ConnectionHandler(this, socket)

class ConnectionHandler

  constructor: (@sockets, @socket) ->
    @socket.on 'adduser',                @addUser
    @socket.on 'playlist',               @addSong
    @socket.on 'chat',                   @updateChat
    @socket.on 'disconnect',             @disconnect
    @socket.on 'enque',                  @enqueFirstSong
    @socket.on 'sync',                   @syncPlayback
    @socket.on 'mastersocketplayerdata', @syncPlaybackForAllUsers

    @emitToAll 'updateplaylist', playlist

  emitToAll: (args...) =>
    @sockets.emit(args...)

  emitToMyself: (args...) =>
    @socket.emit(args...)

  emitToOthers: (args...) =>
    @socket.broadcast.emit(args...)

  setMaster = (socket) =>
    master = socket.id
    socket.master = true

  isFirstUser = =>
    Object.keys(usernames).length == 0

  addUser: (username) =>
    @socket.username = username
    setMaster(this) if isFirstUser()
    usernames[username] = username

    @emitToMyself 'updatechat', 'Playlist', 'you have connected'
    @emitToOthers 'updatechat', 'Playlist', "#{username} has connected"
    @emitToAll 'updateusers', usernames

  addSong: (song) =>
    id = getYouTubeID(song)

    if !playlist[id]?
      playlist[id] = id
      @emitToMyself 'updatechat', 'Playlist', "You added #{id} to the playlist"
      @emitToOthers 'updatechat', 'Playlist', "#{@socket.username} added #{id} to the playlist"
      @emitToAll 'updateplaylist', playlist

  updateChat: (data) =>
    @emitToAll 'updatechat', @socket.username, data

  disconnect: =>
    delete usernames[@socket.username]
    @emitToAll 'updateusers', usernames
    @emitToOthers 'updatechat', 'Playlist', "#{@socket.username} has disconnected"

  enqueFirstSong: =>
    @emitToMyself 'enquefirstsong'

  syncPlayback: =>
    if @socket.id != master
      @sockets.socket(master).emit('getcurrentsongdata')

  syncPlaybackForAllUsers: (id, time) =>
    @emitToOthers 'syncallusers', id, time


console.log "listening on port #{port}"
