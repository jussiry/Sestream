/**
 * @author jussir
 */


MSG_LIKE = 1
MSG_DONT_LIKE = 2
MSG_READ = 3
MSG_NO_STATE = 0

animTime = 300; //  foreground elements (links) 150, background 300 ms

function init_msg($msg, msg_hash) {
  //var $pic = $('.msg_user_pic', $msg);
  var $left_side = $('.msg_left_side', $msg);
  var $content = $('.msg_content', $msg);
  var $text = $('.msg_text', $msg);
  var $info = $('.msg_info', $msg);
  var curStatus = $msg.attr('status');
  
  $('#wrapper').append($msg);
  // adjust message pic and text vertical position:
  height = Math.max($left_side.outerHeight(), $content.outerHeight())
  $left_side.css('margin-top', (height-$left_side.outerHeight())/2) // - 3 because of padding mismatch on .msg_text
  $content.css('margin-top', (height-$content.outerHeight())/2)
  $msg.remove();
  
  // message "button" animations:
  //msg_bg_color = lightColorByStatus(status);
  
  /*$('.msg_user_pic', $msg).click( function(ev) {
    var login = $(this).attr('href').split('/').pop()
    internalLinkClicked(ev, '/user_partial/'+login);
    return false;
  })*/
  
  $('.msg_user_pic', $msg).hover(function() { // .msg_pic_and_info_container
    var $pic = $(this); // $('.msg_user_pic', $(this));
    $('#small_user_info').css({'display': 'block', 'top': $pic.offset().top - 13 + 'px',
                  'left': $pic.offset().left + $pic.width() + 3 + 'px'})
    var login = $msg.attr('user_login')
    var uh = user_data[login]
    if (uh == null) {
      $('#sui_name').html("No user data found");
      $('#sui_login,#sui_percentage,#sui_location,#sui_description,#sui_salience').html('');
    }
    else {
      $('#sui_name').html(uh.name+' &nbsp')
      $('#sui_percentage').html('('+uh.percentage+'%)')
      $('#sui_login').html(login+', ')
      $('#sui_location').html(uh.location)
      $('#sui_description').html(uh.description)
      var mins_since_created = Math.round((new Date() - dateFromISO(msg_hash.created_at)) / 1000 / 60);
      $('#sui_salience').html('salience:  ' + round_dec(msg_hash.base_sal,2) + ' * ('+mins_since_created+" mins ago) = <span style='font-weight:bold; color:#666;'>" + round_dec(msg_hash.salience,2)+'</span>' )
    }
    //var $sui = $('#small_user_info').remove()
    //$(this).append($sui);
  }, function() {
    $('#small_user_info').css('display', 'none');
  })
  
  $('.msg_user_pic', $msg).click( function(){ $('#small_user_info').css('display', 'none'); } );
  
  // change color of already answered:
  if (curStatus == MSG_LIKE)
    $text.css({'border-color':strongGreen, 'background-color':lightGreen});
  else if (curStatus == MSG_DONT_LIKE)
    $text.css({'border-color':strongRed, 'background-color':lightRed});
  else if (curStatus == MSG_READ)
    $text.css('background-color', lightGray);
  
  
  $text.hover(function() {
    curStatus = $(this).parents('.message').attr('status');
  }, function() {
    // When mouse off, return the background based on the actual status
    msgTextCssNormal($msg);
    //curStatus = null;
    $msg.hoverState = -1;
  });
  
  $text.mousemove(function(ev) {
    if ($msg.onLink) { return; }
    //alert('moved. cur_S'+curStatus+'  click_S'+$msg.hoverState)
    var x = ev.pageX - $text.offset().left;
    var width = $text.outerWidth() // could/should be calculated in windowResized() fuction
    var newState = x < (1/3*width) ? MSG_DONT_LIKE :
                   x < (2/3*width) ? MSG_READ      : MSG_LIKE;
    //alert('old state: '+$msg.hoverState+' new state: '+newState)
    if ($msg.hoverState == undefined || $msg.hoverState != newState) {
      $msg.hoverState = newState;
      if (newState == $msg.attr('status'))
        msgTextCssNormal($msg);
      else
        animMsgHoverBg($(this), newState);
      //$(this).children().animate({ backgroundColor: lightColorByStatus(newState) },  { duration: 2*animTime/3, queue: false });
    }
  });
    
  $text.click(function(ev) {
    if ($msg.onLink) { return;  }
    //alert('plaa');
    var newStatus = $msg.hoverState;
    var oldStatus = parseInt($(this).parents('.message').attr('status'));
    //$cont = $(this).parent()
    change_response($msg, newStatus);
    msgTextCssNormal($msg);
  });
  
  $('.link_out', $msg).each(function(){
    $(this).attr('target', '_blank');
    $(this).click(function(){ change_response($msg, $msg.hoverState, true); });
  })
  
  $('.link_out', $msg).hover(function() {
    $msg.onLink = true;
    //$msg.hoverState = curStatus != MSG_DONT_LIKE ? MSG_LIKE : MSG_DONT_LIKE;
    $(this).css('backgroundColor','#fff').animate({ backgroundColor:'#91D3FF', color:'white' }, { duration: animTime, queue: false });
    if ($msg.hoverState != MSG_LIKE) {
      $msg.hoverState = MSG_LIKE;
      animMsgHoverBg($(this).parents('.msg_text'), MSG_LIKE);
    }
    //$(this).click(function(ev) { internalLinkClicked(ev, '/user_partial/'+login); return false; })
  }, function() {
    $msg.onLink = false;
    //$msg.hoverState = null;
    $(this).stop().css({ background: 'none', color:'#2AADD5' })
  });
  
  
  $('.user_link', $msg).hover(function() {
    $msg.onLink = true;
    $msg.hoverState = curStatus;
    $el = $(this);
    //$el.click(function(ev) { internalLinkClicked(ev, '/user_partial/'+login); return false; })
    var login = $(this).attr('href').split('/').pop()
    $el.click(function(ev) {
      openPage(PAGE_USER, login);
      return false;
    })
    $el.prepend("<span class='small'>@</span>").css({ background: '#fff' }).addClass('small_padding')
            .animate({ backgroundColor:'#60E59C', color:'white' }, { duration: animTime, queue: false });
    animMsgHoverBg($(this).parents('.msg_text'), $msg.hoverState);
  }, function() {
    $el.stop().removeClass('small_padding').css({ background: 'none', color: '#42C590' }).children('.small').remove();
    $msg.onLink = false;
    $msg.hoverState = null;
  });
  
  $('.hashtag_link', $msg).hover(function() {
    $el = $(this);
    var tag_name = $el.html()
    $el.prepend("<span class='small'>#</span>").css({ background: '#fff' }).addClass('small_padding')
        .animate({ backgroundColor:'#EDBF71', color:'white' }, { duration: animTime, queue: false });
    $el.click(function(ev) {
      //internalLinkClicked(ev, '/main_page/search/?search_txt='+escape($(this).attr('href')));
      openPage(PAGE_HASHTAG, tag_name)
      return false;
    })
    $msg.onLink = true;
    $msg.hoverState = curStatus;
    animMsgHoverBg($(this).parents('.msg_text'), $msg.hoverState);
  }, function() {
    $el.stop().removeClass('small_padding').css({ background: 'none', color: '#BA9232' }).children('.small').remove();
    $msg.onLink = false;
    $msg.hoverState = null;
  });
}

function animMsgHoverBg($txt, newStateIfClicked) {
  // hide msg_info:
  var $msg_info = $txt.next();
  if( parseFloat($msg_info.css('opacity')) > 0 )
    $msg_info.animate({opacity: 0}, { duration: animTime/2, queue: false });
  // change txt bg:
  if (newStateIfClicked == MSG_NO_STATE)
    $('.bg_status_img', $txt).css({ 'display' : 'none' })
  else {
    $('.bg_status_img', $txt).css({ 'display' : 'block', 'opacity' : 0 })
          .attr('src', '/images/msg_respond_bg_'+newStateIfClicked+'.png')
          .animate({ 'opacity' : 1 }, { duration: animTime, queue: false } );
    //
  }
  //var curStatus = $txt.parents('.message').attr('status');
  
  $txt.stop().css({ 'backgroundColor': '#fff',
              'z-index': 2,
              'borderColor': '#fff' }); // 'borderWidth': '2px 2px 2px 2px', 'padding': '13px 9px'
  
  //animateBorders($txt, strongColorByStatus(newStateIfClicked), animTime);
}

function msgTextCssNormal($msg) {
  //alert('plaa '+$msg_text)
  var status = $msg.attr('status');
  $('.msg_text',$msg).css({'z-index': 0, 'backgroundColor' : lightColorByStatus(status)}); // 'borderWidth' : '1px', 'padding' : '14px 10px'
  animateBorders($('.msg_content',$msg).children(), (status!=MSG_READ ? strongColorByStatus(status) : '#fff'), animTime)
  //$msg_content.children().css({'borderColor' : (status!=MSG_READ ? strongColorByStatus(status) : '#fff')})
  $('.bg_status_img', $msg).animate({ 'opacity': 0 }, { duration: animTime, queue: false } )
  $('.msg_info', $msg).animate({opacity: 1}, animTime/2);
}

function animateBorders($elems, color, time) {
  $elems.animate({ 'borderTopColor': color, 'borderRightColor': color,
     'borderBottomColor': color, 'borderLeftColor': color }, { duration: time, queue: false } )
}

function change_response($msg, newStatus, instant) {
  
  $('.bg_status_img', $msg).css({ 'display' : 'none' });
  var $text_and_info = $msg.children('.msg_content').children();
  if (instant)
    $text_and_info.css({ backgroundColor: lightColorByStatus(newStatus), display: 'block' })
  else
    $text_and_info.css(    { backgroundColor: strongColorByStatus(newStatus), display: 'block' })
                  .animate({ backgroundColor: lightColorByStatus(newStatus) }, animTime);
  // set previous as "read"
  var read_msg_ids = [];
  if (current_page == PAGE_NEW) {
    var checkBefore = 2;
    var $elems = $('.message','#page_content')
    var ind = $elems.index($msg)
    var closeToRead = ind - checkBefore < 0; // ..or beginning
    $elems.slice(Math.max(0, ind - checkBefore), ind).each(function(i) {
      var $cur_msg = $(this);
      var responded = $cur_msg.attr('status') > 0;
      if (closeToRead && !responded) {
        $('.msg_content', $cur_msg).children()
            .css('borderColor',lightGray)
            .animate({ backgroundColor: lightGray }, animTime * 5);
        $cur_msg.attr('status', MSG_READ);
        read_msg_ids.push($cur_msg.attr('msg_id'));
      }
      if (responded) closeToRead = true;
    });
  }
  
  // change statuses and update time in javasript:
  var msg_id = $msg.attr('msg_id');
  var time_in_sec = new Date().getTime() / 1000;
  for (i in all_msgs) {
    if (all_msgs[i].id == msg_id) {
      all_msgs[i].status = newStatus;
      all_msgs[i].status_updated = time_in_sec - 0.1; // -0.1 to make selected status first
    }
    else if (read_msg_ids.include(all_msgs[i].id)) {
      all_msgs[i].status = MSG_READ;
      all_msgs[i].status_updated = time_in_sec;
    }
  }
  $msg.attr('status',newStatus); // change status in html - should change everything to read data form js?
  $('.msg_info', $msg).animate({'height': 18}, { duration: animTime, queue: false });
  
  var msgID = $msg.attr('msg_id');
  read_msg_ids = read_msg_ids.join(',')
  
  $.ajax({
    complete: function(request){ $('.msg_info_slot', '#msg_'+msgID).animate({'opacity':1}, animTime) },
    //error: function(request){ alert('plaa'); notice('Failed to connect to server'); }, // does not work; probably because does not get "error response" when server is not running?
    data: 'authenticity_token=' + encodeURIComponent(authenticityToken),
    success: function(data){$('#msg_info_'+msgID).html(data);}, // $('#temp').html(request);
    type: 'post', url:'/message/change_response?msg_id='+msgID+'&status='+newStatus+'&read_msg_ids='+read_msg_ids
  });
  
  // if likes, show more messages from this user:
  if (current_page == PAGE_NEW && (newStatus == MSG_LIKE || newStatus == MSG_READ)) {
    var login = $msg.attr('user_login')
    var unread = $('.message[user_login='+login+'][status=0]').length
    var open = (newStatus == MSG_LIKE ? 2 : 1) - unread
    if (open > 0) show_hidden_msgs(login, open);
  }
}


/*
function internalLinkClicked(event, link_url) {
  initTopMenu(true,'');
  $('#tag_links').hide('slow');
  $('#page_content').animate({ opacity: 0 }, 1500);
  $.ajax({
    complete: function(request){ $('#page_content').animate({ opacity: 1 }, 150); },
    data: 'authenticity_token=' + encodeURIComponent(authenticityToken),
    success: function(request){$('#page_content').html(request);},
    type: 'post', url: link_url
  });
  event.preventDefault();
  return false;
}
*/

function retweet(msg_id) {
  retweet_msg_id = msg_id;
  offset = $('.retweet_icon','#msg_'+msg_id).offset()
  $rtc = $('#retweet_confirmation');
  $rtc.show().offset({ top: offset.top + 29, left: offset.left - 115 })
}

function retweetYes() {
  $.ajax({
    complete: function(request){ $('.msg_info_slot', '#msg_'+retweet_msg_id).animate({'opacity':1}, animTime) },
    data: 'authenticity_token=' + encodeURIComponent(authenticityToken),
    success: function(request){$('#msg_info_'+retweet_msg_id).html(request);},
    type: 'post', url:'/message/retweet_msg?msg_id='+retweet_msg_id
  });
  $('#retweet_confirmation').hide()
}
function retweetQuote() {
  var $textarea = $('#msg_textarea');
  //alert( retweet_msg_id )
  $textarea.attr('value', 'RT ' + $.trim($('#msg_'+retweet_msg_id).find('.msg_text_text').text()))
  $('html, body').animate({scrollTop: $textarea.offset().top-20}, 500, "swing", function() {});
  $('#retweet_confirmation').hide()
}
