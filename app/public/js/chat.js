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

  // Add user when a new one connects.
  socket.on('connect', function() {
    console.log("[event] connect");
    socket.emit('adduser', prompt("Hi, who's there?"));
  });

  // Every 2 seconds, publish current video status.
  every(2000, function() {
    socket.emit('playerData', $("#player").tubeplayer('data'));
  });

  // Play the specified video.
  socket.on('playVideo', function(videoData) {
    console.log("[event] playVideo", videoData);
    playVideo(videoData);
  });

  // Add chat to the list.
  socket.on('updatechat', function (username, data) {
    $('#convo').append('<b>' + username + ':</b> ' + data + '<br>');
  });

  // Update the list of currently connected users.
  socket.on('updateusers', function(data) {
    console.log("[event] updateusers");

    var userListMarkup = $.map(data, function(key, value) {
      return '<div>' + key + '</div>';
    }).join();

    console.log(userListMarkup);

    $('#users').html(userListMarkup);
  });

  // Update the list of queued videos.
  socket.on('updateplaylist', function(data) {
    console.log("[event] updateplaylist");

    var playListMarkup = $.map(data, function(key, value) {
      return '<div>' + key + '</div>';
    }).join();

    $("#queue").html(playListMarkup);
  });

    // socket.on('syncallusers', function(id,time) {
    //   $("#player").tubeplayer("play", {id: id,time:time});
    // });

    // $('#send').click( function() {
    //   var message = $('#data').val();
    //   $('#data').val('');
    //   if(message.indexOf('youtube') != -1){
    //     socket.emit('playlist', message);
    //   }
    //   else {
    //     socket.emit('chat', message);
    //   }
    // });

    // $('#data').keypress(function(e) {
    //   if(e.which == 13) {
    //     $(this).blur();
    //     $('#send').focus().click();
    //     $('#data').focus();
    //   }
    // });

    var playNextSong = function() {
      currentSong = $("#player").tubeplayer('data').videoID;
      nextSong = $("#queue div:contains('" + currentSong+ "')").next().html()
      if(nextSong == null){
        $("#player").tubeplayer('stop');
      }
      else {
        $("#player").tubeplayer("play", nextSong);
      }
    };

    var playVideo = function(videoData) {
      console.log("#playVideo", videoData);

      wait(1000, function() {
        $("#player").tubeplayer("play", videoData);
      });
    };

    $("#player").tubeplayer({
      allowFullScreen: "false",
      initialVideo: "",
      showControls: false,
      autoPlay: false,
      autoHide: true,
      preferredQuality: "default",
      onPlay: function(id){},
      onPause: function(){},
      onStop: function(){},
      onSeek: function(time){},
      onMute: function(){},
      onUnMute: function(){},
      onPlayerEnded: function(){
        playNextSong();
      }
    });

}