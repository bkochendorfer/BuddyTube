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
    socket.emit('addUser', prompt("Hi, who's there?"));
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
    var convo = $('#convo');
    var newMessage = $('<span>')
      .text(data)
      .prepend($('<b>').text(username + ": "))
      .append($('<br>'));

    convo.append(newMessage);
    convo.scrollTop(convo.height());
  };


  // Update the list of currently connected users.
  var updateUsers = function(usernames) {
    $('#users').html(
      $.map(usernames, function(username) {
        return $('<div>').text(username)[0].outerHTML;
      }).join('')
    );
  };


  // Update the list of queued videos.
  var updatePlaylist = function(videoData) {
    $('#queue').html(
      $.map(videoData, function(videoData) {
        return $('<tr>').append($('<td>').text(videoData['title']))[0].outerHTML;
      }).join('')
    );
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
    socket.emit('videoAdded', video);
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
    return str.indexOf('youtube') > -1;
  };


  // When form is submitted, add the video to the playlist.
  $('.content-form').submit(function(e) {
    e.preventDefault();

    var $messageInput = $('#data', this);
    var message = $messageInput.val();
    clearInput($messageInput);

    if (isYouTubeUrl(message)) {
      publishNewVideo(message);
    } else {
      publishNewMessage(message);
    }
  });


  // Initialize YouTube player.
  $("#player").tubeplayer({
    onPlayerEnded: publishVideoFinished,
    allowFullScreen: "false",
    initialVideo: "ah4VQXe8YqU",
    showControls: false,
    autoPlay: false,
    autoHide: true
  });


  // Event subscriptions.
  socket.on('connect', addUser);
  socket.on('playVideo', playVideo);
  socket.on('updateChat', updateChat);
  socket.on('updateUsers', updateUsers);
  socket.on('updatePlaylist', updatePlaylist);


  // Event publications.
  every(2000, publishCurrentVideoStatus);
};
