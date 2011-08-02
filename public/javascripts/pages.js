
/**
 * Functions involving changing page (url) and building them.
 */


PAGE_NEW = 0
PAGE_LIKED = 1
PAGE_OTHER = 2
PAGE_FOLLOWING = 3
PAGE_USER = 4
PAGE_HASHTAG = 5
PAGE_SEARCH = 6
PAGE_NO_JS = 10
current_page = -1
page_str = '';

SORT_BY_SALIENCE = 1
SORT_BY_STATUS_CREATED = 2
SORT_BY_MSG_CREATED = 3
sorted_by = -1

visible_initially = 1  // how many messages show before hiding rest (in PAGE_NEW)

function initSite() {
  if (current_page == PAGE_NO_JS) return;
  
  // TOP MENU WINDOW STICKING:
  var $mc = $('#menu_container');
  if ($mc.length > 0) {
    $mc.floating = false;
    $('#tag_links').css('marginTop', $mc.outerHeight());
    menuOrigPos = $mc.offset().top; // + parseInt($('#wrapper').css('marginTop'))
    $(document).scroll(function(ev){
      if (!$mc.floating && $(document).scrollTop() > menuOrigPos) {
        $mc.css({'position':'fixed', 'top':0})
        $mc.floating = true;
      }
      else if ($mc.floating && $(document).scrollTop() < menuOrigPos) {
        $mc.css({'position':'absolute', 'top': ''})
        $mc.floating = false;
      }
    });
  }
  
  // Init pages:
	sorted_by = SORT_BY_SALIENCE;
	var ps = getPageFromHash();
	l('ps[0] '+ps[0]+' ps[1] '+ps[1]);
	if (all_msgs.length > 0) openPage(ps[0], ps[1]);
	
	startLoadingMessages();
	// set interval to check for hash change ('back' and 'forward' buttons):
	/*
	setInterval(function() {
		var ps = getPageFromHash();
		if (ps[0] != current_page || ps[1] != page_str) {
			//alert('page changed: '+inspect(ps))
			//alert(ps[0])
			//alert(current_page)
			//alert(ps[1] == page_str)
			l('open page again')
			openPage(ps[0], ps[1]);
		}
	}, 1000);*/
}

function getPageFromHash() {
	var hms = window.location.hash.split('/');
	var main = hms[1] == 'new' ? PAGE_NEW :
      		   hms[1] == 'liked' ? PAGE_LIKED :
      		   hms[1] == 'other' ? PAGE_OTHER :
      		   hms[1] == 'following' ? PAGE_FOLLOWING :
      		   hms[1] == 'user' ? PAGE_USER : PAGE_NEW; // PAGE_NEW, if no page
	var str = typeof hms[2] == 'undefined' ? '' : hms[2];
	return [main, str];
}

function openPage(page, str) {
	console.debug('opening page ('+page+') ' + new Date().getMinutes() + ':' + new Date().getSeconds())
	//printStackTrace()
	switch(page) {
	case PAGE_NEW:
	  window.location.hash = '/new';
		if (new_msgs.length > 0) {
			all_msgs = all_msgs.concat(new_msgs);
			sorted_by = -1;
			new_msgs = [];
			//new_msgs_ammount = 0;
			$('head title').html('Sestream');
		}
		init_msg_creators_data();
		$('#new_msgs_link').html('new');
		sort_msgs(SORT_BY_SALIENCE);
		break;
	case PAGE_LIKED:
		window.location.hash = '/liked';
		sort_msgs(SORT_BY_STATUS_CREATED);
		break;
	case PAGE_OTHER:
		window.location.hash = '/other';
		sort_msgs(SORT_BY_STATUS_CREATED);
		break;
	case PAGE_FOLLOWING:
		notice("Page 'Following' is currently not working.");
		return;
		//window.location.hash = '/following';
		//break;
	case PAGE_USER:
		window.location.hash = '/user/'+str;
		sort_msgs(SORT_BY_MSG_CREATED);
		//notice('User pages are currently not working.')
		break;
	case PAGE_HASHTAG:
		notice('Hashtag pages are currently not working.')
		return;
	case PAGE_SEARCH:
		notice('Search pages are currently not working.')
		return;
	}
	
	next_msg_ind = 0;
	current_page = page;
	page_str = typeof str == 'undefined' ? '' : str; // user login or hashtag name
	
	var $newLink = $('a.top_menu_item:eq('+page+')');
	initTopMenu($newLink);
	$newLink.addClass('tm_selected');
	
	$('#page_content').animate({opacity:0}, 250);
	var top = Math.min($(window).scrollTop(), menuOrigPos)
	var animOnEl = $.browser.mozilla ? 'html' : 'body'
	$(animOnEl).animate({'scrollTop': top}, 250, function() {
		$('#page_content').animate({opacity:1}, 150);
		if (all_msgs.length > 0) {
			$('#page_content').html('');
			if (page == PAGE_USER) initUserPage(page_str);
			else                   showMoreMsgs(15);
		}
	});
	
	//if (page == PAGE_NEW || page == PAGE_LIKED || page == PAGE_OTHER || page == PAGE_FOLLOWING) checkUpdate();
	setTimeout(check_if_at_bottom_of_page, 500);
}

function sort_msgs(sort_by, forceSort) {
  if (sorted_by == sort_by && !forceSort) return;
  console.debug('sorting by: ' + sort_by)
  var sort_function;
  if (sort_by == SORT_BY_SALIENCE)
    sort_function = function(a,b) { return b.salience - a.salience };
  else if (sort_by == SORT_BY_STATUS_CREATED)
    sort_function = function(a,b) { return b.status_updated - a.status_updated };
  else if (sort_by == SORT_BY_MSG_CREATED)
    sort_function = function(a,b) { return dateFromISO(b.created_at) - dateFromISO(a.created_at) };
  all_msgs.sort(sort_function);
  sorted_by = sort_by;
}


function showMoreMsgs(ammount) {
	var shown;
	switch(current_page) {
	case PAGE_NEW:
    shown = show_new_messages(ammount);
		break;
	case PAGE_LIKED:
		shown = show_responded_messages([MSG_LIKE], ammount)
		break;
	case PAGE_OTHER:
		shown = show_responded_messages([MSG_DONT_LIKE, MSG_READ], ammount)
		break;
	case PAGE_USER:
		shown = show_user_messages(ammount)
		break;
	//default:
	}
	if (shown == 0) $('#page_content').append("<p>No messages to show.</p>");
	return shown;
}

function show_new_messages(show_ammount) {
  l('show new messages')
  //var $new_elements = $([]);
  //console.debug('after show_new_messages: '+inspect(msg_creators_data));
  var msgs_shown = 0;
  $.each(all_msgs.slice(next_msg_ind), function(i, mh) {
    next_msg_ind += 1;
    if (mh.status != 0) return; // continues to next message
    // "user" in here is retweeter if retweeted, or message creator if normal message:
    var login = mh.retweeter_login ? mh.retweeter_login : mh.creator_login
    var uml = msg_creators_data[login]; // msg_creators_data for creator of this message
    if (typeof uml == 'undefined') { // DEBUG
      alert ('error; user data not found for: '+login)
      return false;
    }
    
    // show message if not too many already visible (and update msg_creators_data accordingly):
    if (uml.visible < visible_initially) {
      var $new_msg = create_msg(mh)
      $('#page_content').append($new_msg);
      //init_msg($new_msg);
      //$new_elements.append($new_msg)
      uml.visible += 1;
      uml.last_vis_ind = next_msg_ind + i;
      if (!uml.link_visible && uml.visible == visible_initially && uml.msgs > visible_initially) {
        // add link to more visible:
        var $more_link = $( $('#hidden_msgs_tmplt').jqote( {'login': login, 'msgs_left': uml.msgs-visible_initially }, '#') );
        $('.msg_left_side', $new_msg).append($more_link);
        $more_link.css('left', (55 - $more_link.width())/2 + 'px');
      }
      msg_creators_data[login] = uml;
      msgs_shown += 1;
      if (msgs_shown == show_ammount)
        return false;
    }
  });
  //next_msg_ind = next_msg_ind + show_ammount;
  //alert($new_elements.length)
  //$('#page_content').append($new_elements);
  return msgs_shown;
}


function initUserPage(login) {
	$('#page_content').append( $('#user_template').jqote(user_data[login], '#') )
	if (user_data[login].following)
		$('#following').css('backgroundColor', '#B1E060').html('Following');
	var shown = showMoreMsgs(15);
	var $aml = $('#all_msgs_link')
	bgAnimLoop($aml, '#EDE480', $aml.css('backgroundColor'), 900, true);
	$aml.attr('title', 'Loading messages...')
	//'#B1E060'
	
	$.ajax({
		complete: function(request){ userMsgsLoaded() },
		data: 'authenticity_token=' + encodeURIComponent(authenticityToken),
		success: function(request){$('#ajax_scripts').append(request);},
		type: 'post', url:'/user/all_msgs_from_server?login='+login
	});
}

function userMsgsLoaded() {
	var $aml = $('#all_msgs_link')
	bgAnimLoop.ON = false;
	$aml.stop(true).css('backgroundColor', '').removeAttr('title')
	var added = addNewMsgsToAllMsgs();
	if (added > 0) {
		sort_msgs(SORT_BY_MSG_CREATED, true)
		$('#messages').html('')
		next_msg_ind = 0;
		showMoreMsgs(15);
	}
}

function addNewMsgsToAllMsgs() {
  l('addNewMsgsToAllMsgs')
	var added = 0;
	// go through new messages, and add them to all_msgs, unless that message already exist
	_(new_msgs).each(function(msg,i) {
	  var found = _(all_msgs).detect(function(m){
	    return m.id === msg.id;
	  });
	  if (!found) {
	    //log('not found')
	    //log(msg)
	    all_msgs.push(msg);
	    added += 1;
	  }
	});
	new_msgs = [];
	//new_msgs_ammount = 0;
	return added;
}


function show_user_messages(show_ammount) {
	console.debug('show user messages, next_msg_ind: '+next_msg_ind)
	var msgs_shown = 0;
	$.each(all_msgs.slice(next_msg_ind), function(i, mh) {
		next_msg_ind += 1;
		var login = mh.retweeter_login ? mh.retweeter_login : mh.creator_login
		if (login == page_str) {
			var $new_msg = create_msg(mh)
			$('#messages').append($new_msg);
			//init_msg($new_msg);
			msgs_shown += 1;
			if (msgs_shown == show_ammount)
				return false;
		}
	});
	return msgs_shown;
	//next_msg_ind = next_msg_ind + show_ammount;
}

function initTopMenu($selected_link) {
	$('.tm_selected').removeClass('tm_selected');
	$('.selected_tag').removeClass('selected_tag');
    
	$('.top_menu_item').unbind('mouseenter mouseleave').css('backgroundColor', '');
	$('.top_menu_item').not($selected_link).css('backgroundColor', '#fff').hover(function() {
		$(this).animate({backgroundColor:'#ccf08e'}, 150);
	}, function() {
		$(this).animate({backgroundColor:'#fff'}, 150);
	});
	
	/*
	$('.tag_menu_item').unbind('mouseenter mouseleave');
	$('.tag_menu_item').not($selected_link).css('backgroundColor', '#fff').hover(function() {
		$(this).animate({backgroundColor:'#E8DDAE'}, 150);
	}, function() {
		$(this).animate({backgroundColor:'#fff'}, 150);
	});*/
}

function init_msg_creators_data() {
	msg_creators_data = {} // messages left per user in new msgs page { visible, msgs_left, last_vis_ind }
	
	$.each(all_msgs, function(i, mh) {
		//console.debug("hello world,");
		if (mh.status != 0) return;
		var login = mh.retweeter_login ? mh.retweeter_login : mh.creator_login
		var uml = msg_creators_data[login];
		if (typeof uml == 'undefined') {
			uml = { 'visible': 0, 'msgs': 1, 'link_visible': false };
		}
		else
			uml.msgs += 1;  // count the ammount of messages from this user
		msg_creators_data[login] = uml;
	});
	//console.debug('after init: '+inspect(msg_creators_data));
}

function create_msg(mh) {  // mh = message hash
	var $msg = $( $('#msg_template').jqote(mh, '#') )
	if (mh.retweeter_login) {
		//alert('retweeter found: '+mh.creator_login)
		var $img_link = $('.msg_user_pic',$msg);
		$('img', $img_link).remove();
		$msg.attr('user_login', mh.retweeter_login)
		$('.msg_user_pic',$msg).attr('title', mh.retweeter_login+' retweets from '+mh.creator_login)
				.append("<img src='/images/retweet_bg.png' style='position:absolute' />")
				.append("<img src='"+mh.retweeter_pic+"' class='retweeter rc5' />")
				.append("<img src='"+mh.creator_pic+"' class='orig_creator rc5' />")
	}
	init_msg($msg, mh);
	return $msg
}

function show_hidden_msgs(login,msg_ammount) {
	var found = 0;
	//var $hid_cont = $('#hid_cont_'+login);
	//var origHeight = $hid_cont.outerHeight();
	var $last_msg = $('.message[user_login='+login+']:last')
	var $more_link = $('.more_msgs_by_user',$last_msg).remove();
	if ($more_link.length == 0)
		return; // return if no more messages to show (more-link doesn't exist)
	var start_ind = msg_creators_data[login].last_vis_ind + 1
	//  add hidden messages:
	$.each(all_msgs.slice(start_ind), function(ind, mh) {
		var msg_login = mh.retweeter_login ? mh.retweeter_login : mh.creator_login;
		if(msg_login == login && mh.status == 0) {
			// add msg:
			var $new_msg = create_msg(mh);
			$last_msg.after($new_msg);
			//init_msg($new_msg);
			// anim:
			var h = $new_msg.height()
			$new_msg.css({'opacity':0, 'height':0}).animate({'opacity':1, 'height':h}, 500,
												function(){ $new_msg.css('height','') });
			// update stats:
			$last_msg = $new_msg;
			msg_creators_data[login].visible += 1
			msg_creators_data[login].msgs_left -= 1
			msg_creators_data[login].last_vis_ind = start_ind + ind
			found += 1
			if(found == msg_ammount) return false; // break each loop
		}
	})
	//  change or remove hidden link;
	var msgs_left = msg_creators_data[login].msgs - msg_creators_data[login].visible;
	if (msgs_left > 0) {
		$('.msg_left_side', $last_msg).append($more_link);
		$more_link.html(msgs_left+' more');
		l($more_link.width())
		$more_link.css('left', (55 - $more_link.width())/2 + 'px');
	}
	//  animate container opening:
	//var newHeight = $hid_cont.height();
	//$hid_cont.height(origHeight).animate({'height': newHeight}, 500, function(){ $hid_cont.css('height','') });
}


// LIKED and OTRHER -pages

function show_responded_messages(statuses, how_many) {
	var msgs_shown = 0;
	var msgs_checked = 0;
	$.each(all_msgs.slice(next_msg_ind), function(i, mh) {
		msgs_checked += 1;
		if (!statuses.include(mh.status)) return;
		var $new_msg = create_msg(mh)
		$('#page_content').append($new_msg);
		//init_msg($new_msg);
		msgs_shown += 1;
		if (msgs_shown == how_many)
			return false;
	});
	//alert('next_msg_ind before: '+next_msg_ind)
	next_msg_ind += msgs_checked;
	//alert('next_msg_ind after: '+next_msg_ind)
	return msgs_shown;
}

// LOAD CONTENT AUTOMATICALLY AT THE BOTTOM OF PAGE:
bottomTimeout = -1;
function check_if_at_bottom_of_page() {
	clearTimeout(bottomTimeout);
	if (next_msg_ind < all_msgs.length) {
		if (nearBottomOfPage()) {
		  showMoreMsgs(20);
		}
		bottomTimeout = setTimeout("check_if_at_bottom_of_page()", 200);
	}
}
function nearBottomOfPage() {
	var fromBottom = pageHeight() - ($(window).scrollTop() + $(window).height());
	return fromBottom < 100;
}
function pageHeight() {
  return Math.max(document.body.scrollHeight, document.body.offsetHeight);
}