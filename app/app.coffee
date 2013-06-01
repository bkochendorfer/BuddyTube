express = require 'express'
getYouTubeID = require 'get-youtube-id'
youtube = require 'youtube-feeds'
app = express()
port = 3000
app.set 'views', "#{ __dirname  }/views"
app.set 'view engine', 'jade'
app.engine 'jade', require('jade').__express

{detect, isEmpty, without, keys, shuffle, first} = require 'underscore'

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
  getMasterVideo() || getDefaultVideo()

getNextVideo = ->
  if isEmpty(playlist)
    getDefaultVideo()
  else
    popVideoOffQueue(playlist)

popVideoOffQueue = (playlist) ->
  videoIds = keys(playlist)
  videoId = first(shuffle(videoIds))

  id: videoId

getMasterVideo = ->
  return unless master = getMasterConnection()
  return unless master.currentVideoId?

  id: master.currentVideoId
  time: master.currentVideoTime

getDefaultVideo = ->
  id: "ah4VQXe8YqU"

class ConnectionHandler

  constructor: (@sockets, @socket) ->
    @socket.on 'adduser',                @addUser
    @socket.on 'playerData',             @savePlayerData
    @socket.on 'playlist',               @addSong
    @socket.on 'chat',                   @updateChat
    @socket.on 'disconnect',             @disconnect
    @socket.on 'enque',                  @enqueFirstSong
    @socket.on 'sync',                   @syncPlayback
    @socket.on 'mastersocketplayerdata', @syncPlaybackForAllUsers
    @socket.on 'videoFinished',          @playNextVideo

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

    @emitToMyself 'updateChat', 'Playlist', 'you have connected'
    @emitToOthers 'updateChat', 'Playlist', "#{username} has connected"
    @emitToAll 'updateusers', getAllUsernames()
    @emitToMyself 'playVideo', getCurrentVideo()

  savePlayerData: (data) =>
    console.log "#savePlayerData"
    @currentVideoId = data.videoID
    @currentVideoTime = data.currentTime

  addSong: (song) =>
    id = getYouTubeID(song)

    if !playlist[id]?
      playlist[id] = id
      @emitToMyself 'updateChat', 'Playlist', "You added #{id} to the playlist"
      @emitToOthers 'updateChat', 'Playlist', "#{@username} added #{id} to the playlist"
      @emitToAll 'updateplaylist', playlist

  updateChat: (data) =>
    @emitToAll 'updateChat', @username, data

  disconnect: =>
    removeConnection(this)
    @emitToAll 'updateusers', getAllUsernames()
    @emitToOthers 'updateChat', 'Playlist', "#{@username} has disconnected"

  enqueFirstSong: =>
    @emitToMyself 'enquefirstsong'

  syncPlayback: =>
    @emitToMaster 'getcurrentsongdata' unless @isMaster()

  syncPlaybackForAllUsers: (id, time) =>
    @emitToOthers 'syncallusers', id, time

  playNextVideo: =>
    @emitToAll 'playVideo', getNextVideo() if @isMaster()


console.log "listening on port #{port}"
