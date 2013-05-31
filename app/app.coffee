express = require 'express'
getYouTubeID = require 'get-youtube-id'
youtube = require 'youtube-feeds'
app = express()
port = 3000
app.set 'views', "#{ __dirname  }/views"
app.set 'view engine', 'jade'
app.engine 'jade', require('jade').__express

{detect, isEmpty, without} = require 'underscore'

app.get '/', (req, res) ->
  res.render 'chatroom'

app.use express.static("#{ __dirname }/public")

playlist = {}
connections = []

io = require('socket.io').listen(app.listen(port))

io.sockets.on 'connection', (socket) ->
  connection = new ConnectionHandler(this, socket)
  connection.master = true if isEmpty(connections)
  addConnection(connection)


addConnection = (connection) ->
  connections.push(connection)

removeConnection = (connection) ->
  connections = without(connections, connection)

getMasterConnection = ->
  detect(connections, (connection) -> connection.isMaster())

getAllUsernames = ->
  usernames = {}

  for connection in connections
    username = connection.username
    usernames[username] = username

  usernames

getCurrentVideo = ->
  "cTuxswB_Rew"

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

  emitToMaster: (args...) =>
    if master = getMasterConnection()
      master.socket.emit(args...)

  isMaster: =>
    !!@master

  addUser: (username) =>
    @username = username

    @emitToMyself 'updatechat', 'Playlist', 'you have connected'
    @emitToOthers 'updatechat', 'Playlist', "#{username} has connected"
    @emitToAll 'updateusers', getAllUsernames()
    @emitToMyself 'playVideo', getCurrentVideo()

  addSong: (song) =>
    id = getYouTubeID(song)

    if !playlist[id]?
      playlist[id] = id
      @emitToMyself 'updatechat', 'Playlist', "You added #{id} to the playlist"
      @emitToOthers 'updatechat', 'Playlist', "#{@username} added #{id} to the playlist"
      @emitToAll 'updateplaylist', playlist

  updateChat: (data) =>
    @emitToAll 'updatechat', @username, data

  disconnect: =>
    removeConnection(this)
    @emitToAll 'updateusers', getAllUsernames()
    @emitToOthers 'updatechat', 'Playlist', "#{@username} has disconnected"

  enqueFirstSong: =>
    @emitToMyself 'enquefirstsong'

  syncPlayback: =>
    @emitToMaster 'getcurrentsongdata' unless @isMaster()

  syncPlaybackForAllUsers: (id, time) =>
    @emitToOthers 'syncallusers', id, time


console.log "listening on port #{port}"
