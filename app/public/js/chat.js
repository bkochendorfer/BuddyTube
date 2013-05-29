window.onload = function() {

  var socket = io.connect('/');

    socket.on('connect', function() {
      socket.emit('adduser', prompt("Hi, who's there?"))
      socket.emit('updateplaylist')
      if (!$("#player").is(":visible")) {
        socket.emit('enque')
      }
      socket.emit('sync')
    });

    socket.on('updatechat', function (username, data) {
      $('#convo').append('<b>'+username + ':</b> ' + data + '<br>');
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

    socket.on('enquefirstsong', function(data) {
      inQueue = $('#queue').children(":first").html()
      setTimeout(function(){
        jQuery("#player").tubeplayer("play", inQueue)
      },1000);
    });

    socket.on('getcurrentsongdata', function(data){
      id = jQuery("#player").tubeplayer('data').videoID
      time = jQuery("#player").tubeplayer('data').currentTime
      socket.emit('mastersocketplayerdata', id, time);
    });

    socket.on('syncallusers', function(id,time) {
      jQuery("#player").tubeplayer("play", {id: id,time:time});
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

    playNextSong = function() {
      currentSong = jQuery("#player").tubeplayer('data').videoID;
      nextSong = $("#queue div:contains('" + currentSong+ "')").next().html()
      if(nextSong == null){
        jQuery("#player").tubeplayer('stop');
      }
      else {
        jQuery("#player").tubeplayer("play", nextSong);
      }
    };

    jQuery("#player").tubeplayer({
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