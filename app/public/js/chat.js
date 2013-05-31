window.onload = function() {

  var wait = function(delay, cb) {
    setTimeout(cb, delay);
  };

  var socket = io.connect('/');

    socket.on('connect', function() {
      console.log("[event] connect");
      socket.emit('adduser', prompt("Hi, who's there?"));
    });

    socket.on('playVideo', function(videoId) {
      console.log("[event] playVideo", videoId);
      playVideo(videoId);
    });

    socket.on('updatechat', function (username, data) {
      $('#convo').append('<b>' + username + ':</b> ' + data + '<br>');
    });

    socket.on('updateusers', function(data) {
      $('#users').empty();
      $.each(data, function(key, value) {
        if (key){
          $('#users').append('<div>' + key + '</div>');
        }
      });
    });

    socket.on('updateplaylist', function(data) {
      console.log("[event] updateplaylist");

      $('#queue').empty();
      $.each(data, function(key, value) {
        $('#queue').append('<div>' + key + '</div>');
      });
      if(! $('#queue').is(':empty')) {
        $('#player').show();
        if($('#queue').children().size() == 1){
          socket.emit('enque');
        }
      }
    });

    // socket.on('enquefirstsong', function(data) {
    //   inQueue = $('#queue').children(":first").html()
    //   setTimeout(function(){
    //     $("#player").tubeplayer("play", inQueue)
    //   },1000);
    // });

    socket.on('getcurrentsongdata', function(data){
      id = $("#player").tubeplayer('data').videoID
      time = $("#player").tubeplayer('data').currentTime
      socket.emit('mastersocketplayerdata', id, time);
    });

    socket.on('syncallusers', function(id,time) {
      $("#player").tubeplayer("play", {id: id,time:time});
    });

    $('#send').click( function() {
      var message = $('#data').val();
      $('#data').val('');
      if(message.indexOf('youtube') != -1){
        socket.emit('playlist', message);
      }
      else {
        socket.emit('chat', message);
      }
    });

    $('#data').keypress(function(e) {
      if(e.which == 13) {
        $(this).blur();
        $('#send').focus().click();
        $('#data').focus();
      }
    });

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

    var playVideo = function(videoId) {
      console.log("#playVideo", videoId);

      wait(1000, function() {
        $("#player").tubeplayer("play", { id: videoId });
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