$(function(){

  var $sendButton = $('.bulk-message button');
  var $messages = $('.bulk-message .messages');

  // Send message to all users
  $sendButton.on('click', function(e) {
    e.preventDefault();
    var recipient = $('input[name=recipients]:checked').val()
    if (!recipient || recipient.length == 0) {
      alert('Select a recipient(s)!')
      return
    }
    // confirm message
    var confirmMessage = "Are you sure?"
    if (recipient == 'patron') {
      confirmMessage = typeof patronUserCount == 'undefined' ? 'X' : patronUserCount;
    } else if (recipient == 'all') {
      confirmMessage = typeof allUserCount == 'undefined' ? 'X' : allUserCount;
    }
    var result = confirm('This will send to '+confirmMessage+' users! Are you sure?');
    if (!result) {
      return;
    }
    // do nothing if no body text
    var $textarea = $('.bulk-message textarea');
    var body = $textarea.val();
    if (typeof body == 'undefined' || body.length == 0) {
      return;
    }
    // update send button
    setSendingButton();
    // ajax call
    var messageData = {'message': {'body': body}};

    console.log(recipient)
    if (recipient == 'patron') {
      var url = '/messages/send_to_patrons'
    } else if (recipient == 'all') {
      var url = '/messages/send_to_all'
    } else {
      // todo
    }
    $.ajax({
      url: url,
      method: 'POST',
      data: messageData,
      success: function(response) {
        setSendButton();
        if (response['success']) {
          $messages.find('p').html("Messages have been queued for send. Check Slack #sms for updates.");
        } else if (response['error']) {
          handleErrorResponse(response);
        }
        $messages.show();
      },
      error: function(response) {
        setSendButton();
        if (response['error']) {
          handleErrorResponse(response);
        }
        $messages.show();
      }
    });
  });

  var setSendingButton = function() {
    $sendButton.prop('disabled', true);
    $sendButton.html('Sending...');
  }

  var setSendButton = function() {
    $sendButton.prop('disabled', false);
    $sendButton.html('Send');
  }

  var handleErrorResponse = function(response) {
    $messages.find('p').html(response['error']);
    var $messagesList = $messages.find('ul');
    $messagesList.empty();
    var messages = response['messages'];
    if (messages) {
      for (var i = 0; i < messages.length; i++) { 
        var message = messages[i];
        var item = $('<li>'+message+'</li>');
        $messagesList.append(item);
      }
    }
  }

  $messages.hide();

  // preview link
  $(".preview-link").click(function(e) {
    e.preventDefault();
    var href = $(e.target).attr('href');
    console.log('preview click', href);
    var textarea = $('textarea');
    if (textarea && textarea.val() && textarea.val().length > 0) {
      href = href + "?message=" + textarea.val();
    }
    window.location = href;
  });
});





