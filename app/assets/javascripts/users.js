$(function(){

  var $phone = $('#phone');
  var locked = false;

  // Initialize tel input
  $phone.intlTelInput({
    initialCountry: ""
  });

  // Handle form submit
  $('.new-user').on('submit', function(e) {
    e.preventDefault();
    if (!locked) {
      if ($phone.intlTelInput("isValidNumber")) {
        locked = true;
        $('.submit').val('...')
        var phoneNumber = $phone.intlTelInput("getNumber");
        $.ajax({
          url: '/users',
          method: 'POST',
          data: {phone: phoneNumber},
          success: function(e){
            $('.new-user').html('Perfect! We just sent a text to ' + phoneNumber)
          },
          error: function(e) {
            locked = false;
            $('.submit').val('JOIN');
            $('.error-message').text('Oops! That didn\'t work for some reason. Try again?').show();
          }
        });
      } else {
        $('.error-message').show();
        locked = false;
      }
    }
  });

  // User messages
  if ($('.messages').length) {
    var el = $('.messages');
    var height = el[0].scrollHeight;
    el.scrollTop(height);
  }

  // Mark as responded
  var $resolvedButton = $('.resolved button');
  $resolvedButton.on('click', function(e){
  // $resolvedButton.on('click', function(e){
    $resolvedButton.prop('disabled',true);
    var resolvedText = $resolvedButton.html();
    var userId = $('#user_id').val();
    if (!userId || typeof userId == 'undefined') {
      return;
    }
    $.ajax({
      url: '/users/'+userId,
      method: 'PUT',
      data: {needs_response: false},
      success: function(data){
        $resolvedButton.hide();
      },
      error: function(req) {
        console.log(req);
        $resolvedButton.removeProp('disabled');
        $resolvedButton.html(resolvedText);
      }
    })
  });

  var $subscribedButton = $('.subscribed-checkbox');
  $subscribedButton.on('change', function(e){
    if (!confirm('Are you sure?')) return;
    var userId = $('#user_id').val();
    if (!userId || typeof userId == 'undefined') {
      return;
    }
    var subscribed = $subscribedButton.is(':checked');
    $.ajax({
      url: '/users/'+userId,
      method: 'PUT',
      data: {subscribed: subscribed},
      success: function(e){
        location.reload();
      },
      error: function(e) {
        alert("There was a problem unsubscribing.");
      }
    });
  });
});
