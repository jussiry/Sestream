// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

l('running app.js')


// global vars:

updateTimeout = -1;
msgs_updated_time = 0; // TODO: check if this right!
new_msgs = [];
//new_msgs_ammount = 0;


/* COLORS:
 * ---------------------------------*/

white = '#ffffff';
gray = '#aaaaaa';
//middleGray = '#cccccc';
lightGray = '#e8e8e8';
strongGreen = '#BCE07D'; //'#B1E060'
//middleGreen = '#D9EDAF'
lightGreen = '#F7FFEA';
strongRed = '#E8AA6D';
//middleRed = '#FCD2B8'
lightRed = '#FFF5ED';
fadeTime = 300;



$(function() {
  l('loaded...')
	// Round corners:
	DD_roundies.addRule('.rc5', '5px', true);
	DD_roundies.addRule('.rc10', '10px', true);
	DD_roundies.addRule('.rc15', '15px', true);
	DD_roundies.addRule('.rc20', '20px', true);
	
	DD_roundies.addRule('.button', '5px', true);
	DD_roundies.addRule('.msg_info', '0 0 10px 10px', true);
	
	if (current_page == PAGE_NO_JS) return;
	
	// SEARCH FIELD
	$('#search_field').keypress(function(ev) {
		//alert(ev)
		if(ev.keyCode == 13) {
			openPage(PAGE_SEARCH)
			//initTopMenu('');
			//$('#tag_links').hide('slow');
			//$('#page_content').animate({ opacity: 0 }, 1500);
			return false;
		}
	})
	
	// NEW TWEET FORM
	
	$('#new_msg_textarea').focusin(function() {
		$('#new_message_length_notice').show('slow');
		$(this).animate({'height': 60})
		$('#submit_message').animate({'marginTop': 13, 'height': 36})
	})
	$('#new_msg_textarea').focusout(function() {
		$('#new_message_length_notice').hide('slow');
		$(this).animate({'height': 20})
		$('#submit_message').animate({'marginTop': 0, 'height': 26})
	})
	
	$('#new_msg_textarea').keypress(function(){
		checkNewMessageLength();
	})
	$('#new_msg_textarea').keyup(function(){
		checkNewMessageLength();
	})
	
	// NOTICE:
	$('#notice').click(function() {
		$(this).hide('slow')
	});
	
	// do after site loaded...
	if (typeof all_msgs == 'undefined' || all_msgs == null)
		all_msgs = [];
	resizeWindow();
	l('loaded done')
});

function resizeWindow() {
	console.debug('resizeWindow..')
	if ($('#wrapper').width() == 0) {
		timeOut(resizeWindow, 100);
		return;
	}
	$('#menu_container').css('width', $('#wrapper').width())
}

function dateFromISO(created_at_str) {
	var d = new Date(created_at_str);
	if (d == 'Invalid Date') // happens on chrome
		d = new Date(created_at_str.substring(0,19).replace('T',' '));
	return d;
}

/*
function animLoadNotice() {
	// make endless loop...
	$('#load_notice').animate({opacity:0.2},1500).animate({opacity:1},1500)
					.animate({opacity:0.2},1000).animate({opacity:1},1000)
					.animate({opacity:0.2},600).animate({opacity:1},600)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},1000).animate({opacity:1},1000)
					.animate({opacity:0.2},1000).animate({opacity:1},1000)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400)
					.animate({opacity:0.2},400).animate({opacity:1},400);
}*/


/*
function checkUpdate() {
	clearTimeout(updateTimeout);
	var update_every_x_min = 15;
	var since_update_min = (new Date() - msgs_updated_time) / 60000
	if (since_update_min > update_every_x_min)
		startLoadingMessages()
	else {
		var update_in_ms = (update_every_x_min - since_update_min) * 60000
		updateTimeout = setTimeout(startLoadingMessages, update_in_ms)
	}
}
*/
function startLoadingMessages() {
	var $nml = $('#new_msgs_link');
	bgAnimLoop($nml, '#EDE480', $nml.css('backgroundColor'), 900, true);
	$nml.attr('title', 'Loading new messages...');
	//'#B1E060'
	
	$.ajax({
    url:'/main_page/update_messages',
		/*data: 'authenticity_token=' + encodeURIComponent(authenticityToken),*/
    //type: 'post',
    success: function(request) {
		  l('request succesfull!')
		  console.log(request);
		  $('#ajax_scripts').append(request);
		  l('new messages after append:')
		  l(new_msgs)
		},
		complete: function(request) {
      msgsLoaded();
    }
	});
	// set new load:
	//clearTimeout(updateTimeout);
	//var update_every_x_min = 0.4; // 15
  //var since_update_min = (new Date() - msgs_updated_time) / 60000
  //var update_in_ms = (update_every_x_min - since_update_min) * 60000
  //l('update_in_ms '+update_in_ms)
  var min_in_ms = 60000;
  setTimeout(startLoadingMessages, 10*min_in_ms);
}

function bgAnimLoop($link, color1, color2, speed, start) {
	if (start) bgAnimLoop.ON = true;
	$link.animate({'backgroundColor': color1}, speed).animate({'backgroundColor': color2}, speed, function() {
		if (bgAnimLoop.ON)
			bgAnimLoop($link, color1, color2, speed)
	});
}

function msgsLoaded() {
  l('msgsLoaded')
	var $nml = $('#new_msgs_link')
	bgAnimLoop.ON = false;
	$nml.stop(true).css('backgroundColor', '').removeAttr('title')
	if (new_msgs.length > 0) {
		$nml.css('backgroundColor', '#EDE480')
		$nml.html("<span class='new_msgs_num'>"+new_msgs.length+"</span>new")
	}
}


function notice(note) {
	$('#notice').html(note + ' &nbsp(click to close)').show('slow');
}

/*
function showContent() {
	$('#page_content').stop().animate( {opacity:1}, 200);
}*/

//$().mousemove(function(ev){
//   mouseX = ev.pageX;
//   mouseY = ev.pageY;
//});

/*
function HexToR(h) {return parseInt((cutHex(h)).substring(0,2),16)}
function HexToG(h) {return parseInt((cutHex(h)).substring(2,4),16)}
function HexToB(h) {return parseInt((cutHex(h)).substring(4,6),16)}
function cutHex(h) {return (h.charAt(0)=="#") ? h.substring(1,7):h}
function HexToRGB(h) {return 'rgb('+HexToR(h)+', '+HexToG(h)+', '+HexToB(h)+')'}
*/


function strongColorByStatus(status) {
	if (status == MSG_LIKE) return strongGreen;
	else if (status == MSG_DONT_LIKE) return strongRed;
	else if (status == MSG_READ) return gray;
	else return white;
}

function lightColorByStatus(status) {
	if (status == MSG_LIKE) return lightGreen;
	else if (status == MSG_DONT_LIKE) return lightRed;
	else if (status == MSG_READ) return lightGray;
	else return white;
}


function checkNewMessageLength() {
	var txt = $('#new_msg_textarea').val();
	var charsLeft = 140 - txt.length
	var color = charsLeft < 0 ? 'red' : 'green'
	$('#chars_left').html("<span style='color:"+color+"'>"+charsLeft+"<span>")
	if (charsLeft < 0)
		$('#submit_message').attr('disabled', 'disabled');
	else
		$('#submit_message').attr('disabled', '');
}

function getStyle(el,styleProp)
{
	if (el.currentStyle)
		var y = el.currentStyle[styleProp];
	else if (window.getComputedStyle)
		var y = document.defaultView.getComputedStyle(el,null).getPropertyValue(styleProp);
	return y;
}

function stop(ev) {
	ev.preventDefault();
	return false;
}



function round_dec(number, decimals) { // round with given decimal precision:
	return Math.round(number * Math.pow(10,decimals)) / Math.pow(10,decimals);
}

function l(txt)   { console.log(txt); }
function log(txt) { console.log(txt); }

function inspect(o) {
	str = ""
	$.each(o, function(index, value) { 
	  str = str + index + ': ' + value + '; '
	});
	return str.length == 0 ? "no values found. empty or not valid for $.each()." : str
}

function et(eval_str) { // eval test function, good for underscore.js functions
  // but not as fast as writing the whole function, so use mainly for debugging
  return function(a,b,c,d) { return eval(eval_str); };
}


jQuery.fn.outerHTML = function(s) {
	return (s) ? this.before(s).remove()
				: jQuery("<p>").append(this.eq(0).clone()).html();
}

Array.prototype.index = function(val) {
  for(var i = 0, l = this.length; i < l; i++) {
    if(this[i] == val) return i;
  }
  return null;
}

Array.prototype.include = function(val) {
  return this.index(val) !== null;
}

/*
myId = function(me){ return me.id ? '#' + me.id : '' }
myTag = function(me){ return me.tagName ? me.tagName.toLowerCase() : '' }
myClass = function(me){ return me.className ? '.' + me.className.split('').join('.') : '' }
inspect = function(me){
  var path = [myTag(me) + myId(me) + myClass(me)];
  $(me).parents().each(function() {
          path[path.length] = myTag(this) + myId(this) + myClass(this);
  });
  alert(path.join(' < '));
}*/


function defined(a) {
	return (typeof a != 'undefined');
}
/*
function test(a,b) {
	alert(defined(a))
	alert(defined(b))
}
test("plaa")
*/
//Object.prototype.isDefined = function() { return (typeof this != 'undefined'); }
//alert(asd.isDefined())

function printStackTrace() {
  var callstack = [];
  var isCallstackPopulated = false;
  try {
    i.dont.exist+=0; //doesn't exist- that's the point
  } catch(e) {
    if (e.stack) { //Firefox
      var lines = e.stack.split('\n');
      for (var i=0, len=lines.length; i<len; i++) {
        if (lines[i].match(/^\s*[A-Za-z0-9\-_\$]+\(/)) {
          callstack.push(lines[i]);
        }
      }
      //Remove call to printStackTrace()
      callstack.shift();
      isCallstackPopulated = true;
    }
  }
  if (!isCallstackPopulated) { //IE and Safari
    var currentFunction = arguments.callee.caller;
    while (currentFunction) {
      var fn = currentFunction.toString();
      var fname = fn.substring(fn.indexOf("function") + 8, fn.indexOf('')) || 'anonymous';
      callstack.push(fname);
      currentFunction = currentFunction.caller;
    }
  }
  output(callstack);
}

function output(arr) {
  //Optput however you want
  alert(arr.join('\n\n'));
}
