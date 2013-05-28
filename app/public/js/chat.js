window.onload = function() {

  var socket = io.connect('/');

    socket.on('connect', function() {
      socket.emit('adduser', prompt("Hi, who's there?"))
      socket.emit('updateplaylist')
      socket.emit('enque')
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
        jQuery("#player").tubeplayer("play", key);
      });
      if(! $('#queue').is(':empty')) {
        $('#player').show();
      }
    });

    socket.on('enquefirstsong', function(data) {
      // This doesn't work
      // var thingy = $('#queue').children(":first").html()
      // console.log(thingy)
      // console.log(jQuery("#player").tubeplayer("play", thingy));
      // $('#player iframe').onload = function(){ jQuery("#player").tubeplayer("play", $('#queue').children(":first").html()) };
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

}