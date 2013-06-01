express = require 'express'
getYouTubeID = require 'get-youtube-id'
youtube = require 'youtube-feeds'
{detect, map, isEmpty, without} = require 'underscore'


# Application config

port = 3000
app = express()
app.use express.static("#{ __dirname }/public")
app.set 'views', "#{ __dirname  }/views"
app.set 'view engine', 'jade'
app.engine 'jade', require('jade').__express


# Routes

app.get '/', (req, res) ->
  res.render 'chatroom'


# Initialize the application (along with Socket.io)
io = require('socket.io').listen(app.listen(port))

io.sockets.on 'connection', (socket) ->
  connection = new ConnectionHandler(this, socket)
  connection.master = true if isEmpty(connections)
  addConnection(connection)


# Cache of Youtube video ids in the queue.
playlist = []


# Cache of connected users.
connections = []


# Add a connection to the cached list.
addConnection = (connection) ->
  connections.push(connection)


# Remove a connection from the cached list.
removeConnection = (connection) ->
  connections = without(connections, connection)


# Find the `master` connection.
getMasterConnection = ->
  detect(connections, (connection) -> connection.isMaster())


# Get usernames of all users currently connected.
getAllUsernames = ->
  map(connections, (connection) -> connection.username)


# Get the currently playing video.
getCurrentVideo = ->
  getMasterVideo() || getDefaultVideo()


# Get the next video to play.
getNextVideo = ->
  if isEmpty(playlist)
    getDefaultVideo()
  else
    popVideoOffQueue(playlist)


# Remove the next video from the cached list.
popVideoOffQueue = (videos) ->
  id: playlist.shift()


# Get the video that is currently being played on the `master` connection.
getMasterVideo = ->
  return unless master = getMasterConnection()
  return unless master.currentVideoId?

  id: master.currentVideoId
  time: master.currentVideoTime


# Get the default video: "Bwaaamp bwamp bwamp bwamp bwamp bwwaaaaamp.""
getDefaultVideo = ->
  id: "ah4VQXe8YqU"


class ConnectionHandler

  constructor: (@sockets, @socket) ->
    @socket.on 'addUser',       @addUser
    @socket.on 'playerData',    @savePlayerData
    @socket.on 'chat',          @updateChat
    @socket.on 'disconnect',    @disconnect
    @socket.on 'videoAdded',    @addVideo
    @socket.on 'videoFinished', @playNextVideo


  # Emit an event to all connections.
  emitToAll: (args...) =>
    @sockets.emit(args...)


  # Emit an event to this connection.
  emitToMyself: (args...) =>
    @socket.emit(args...)


  # Emit an event to other connections.
  emitToOthers: (args...) =>
    @socket.broadcast.emit(args...)


  # Determine whether this is the `master` connection.
  isMaster: =>
    !!@master


  # Save the status of the currently playing video on this connection.
  savePlayerData: (data) =>
    @currentVideoId = data.videoID
    @currentVideoTime = data.currentTime


  # A new user has joined the ol' BuddyChoob.
  addUser: (username) =>
    @username = username

    @emitToAll 'updateUsers', getAllUsernames()
    @emitToOthers 'updateChat', 'Playlist', "#{username} has connected"
    @emitToMyself 'updatePlaylist', playlist
    @emitToMyself 'updateChat', 'Playlist', 'you have connected'
    @emitToMyself 'playVideo', getCurrentVideo()


  # A user has disconnected from the ol' BuddyChoob.
  disconnect: =>
    removeConnection(this)
    @emitToAll 'updateUsers', getAllUsernames()
    @emitToOthers 'updateChat', 'Playlist', "#{@username} has disconnected"


  # A new video has been added to ol' BuddyChoob.
  addVideo: (video) =>
    id = getYouTubeID(video)

    playlist.push(id)

    @emitToAll 'updatePlaylist', playlist
    @emitToOthers 'updateChat', 'Playlist', "#{@username} added #{id} to the playlist"
    @emitToMyself 'updateChat', 'Playlist', "You added #{id} to the playlist"


  # A new chat has been posted in the ol' BuddyChoob.
  updateChat: (data) =>
    @emitToAll 'updateChat', @username, data


  # Start the next video in the ol' BuddyChoob.
  playNextVideo: =>
    if @isMaster()
      @emitToAll 'playVideo', getNextVideo()
      @emitToAll 'updatePlaylist', playlist


console.log "listening on port #{port}"
