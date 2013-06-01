window.onload = function() {

  var socket = io.connect('/');

  // Perform `cb` after `delay` ms.
  var wait = function(delay, cb) {
    setTimeout(cb, delay);
  };

  // Perform `cb` every `interval` ms.
  var every = function(interval, cb) {
    setInterval(cb, interval);
  };

  // Add a user.
  var addUser = function() {
    socket.emit('adduser', prompt("Hi, who's there?"));
  };

  // Play a video given the specificed data.
  //
  // videoData
  //    - id: The YouTube video id.
  //    - time: The timestamp at which to start the video.
  //
  var playVideo = function(videoData) {
    wait(1000, function() {
      $("#player").tubeplayer("play", videoData);
    });
  };

  // Add chat to the list.
  var updateChat = function (username, data) {
    $('#convo').append('<b>' + username + ':</b> ' + data + '<br>');
  };

  // Update the list of currently connected users.
  var updateUsers = function(data) {
    var userListMarkup = $.map(data, function(key, value) {
      return '<div>' + key + '</div>';
    }).join();

    $('#users').html(userListMarkup);
  };

  // Update the list of queued videos.
  var updatePlaylist = function(data) {
    var playListMarkup = $.map(data, function(key, value) {
      return '<div>' + key + '</div>';
    }).join();

    $("#queue").html(playListMarkup);
  };

  // Publish current video status.
  var publishCurrentVideoStatus = function() {
    socket.emit('playerData', $("#player").tubeplayer('data'));
  };

  // Publish a new chat message.
  var publishNewMessage = function(message) {
    socket.emit('chat', message);
  };

  // Publish a new video addition.
  var publishNewVideo = function(video) {
    socket.emit('playlist', video);
  };

  // Publish an event when video is finished.
  var publishVideoFinished = function() {
    socket.emit('videoFinished');
  };

  // Clear an input.
  var clearInput = function($input) {
    $input.val('');
  };

  // Determine whether a string is a YouTube url.
  var isYouTubeUrl = function(str) {
    str.indexOf('youtube') > -1
  };

  socket.on('connect', addUser);
  socket.on('playVideo', playVideo);
  socket.on('updateChat', updateChat);
  socket.on('updateusers', updateUsers);
  socket.on('updateplaylist', updatePlaylist);

  every(2000, publishCurrentVideoStatus);

  // When form is submitted, add the video to the playlist.
  $('.content-form').submit(function(e) {
    e.preventDefault();

    var $messageInput = $('#data', this);
    var message = $messageInput.val();
    clearInput($messageInput);

    isYouTubeUrl(message) ? publishNewVideo(message) : publishNewMessage(message);
  });

  $("#player").tubeplayer({
    onPlayerEnded: publishVideoFinished,
    allowFullScreen: "false",
    showControls: false,
    autoPlay: false,
    autoHide: true
  });

}
