var buttonWidth = 0;

function resizeUI() {
  var h = $(window).height();
  var w = $(window).width();
  var t = $('#tabs');
  var outerH = h - t.offset().top - t.next().outerHeight(true);
  t.outerHeight(outerH);

  var paneH = t.height() - t.find('.ui-tabs-nav').outerHeight(true);
  t.find('.ui-tabs-panel').outerHeight(paneH);
}
function isSameDay(one, two) {
  return one.getFullYear() == two.getFullYear() &&
         one.getMonth() == two.getMonth() &&
         one.getDate() == two.getDate()
}
function updateUI(data) {
  $('#current-activity').html(data.current);
  $('.stop-tracking').button().find('span').width(buttonWidth);
  $('#today-tab').html(data.today);
  $('#week-tab').html(data.week);
}
function millisecondsToWords(num) {
  var total_minutes = Math.floor(num / 60000);
  if (total_minutes == 0) {
    return("0min");
  }

  var minutes = total_minutes % 60;
  var total_hours = Math.floor(total_minutes / 60);
  var hours = total_hours % 24;
  var days = Math.floor(hours / 24);

  var strings = [];
  if (days > 0) {
    strings.push(days+'d');
  }
  if (hours > 0) {
    strings.push(hours+'h');
  }
  if (minutes > 0) {
    strings.push(minutes+'min');
  }

  return(strings.join(" "));
}
function updateCurrent() {
  var now = new Date();
  $('.activity-duration.activity-running').each(function() {
    var obj = $(this);
    var startedAt = obj.data('startedAt');
    if (typeof(startedAt) == 'undefined') {
      startedAt = new Date(obj.attr('title'));
      obj.data('startedAt', startedAt);
    }
    var diff = now - startedAt;
    obj.html(millisecondsToWords(diff));
  });
}

$(function() {
  $('#tabs').tabs();

  $('#new-activity-form').submit(function(e) {
    e.preventDefault();

    var form = $(this);
    var name = form.find('.activity-name');
    var tags = form.find('.activity-tags');
    var data = {
      'activity[name_with_project]': (name.hasClass('empty') ? "" : name.val()),
      'activity[tag_names]': (tags.hasClass('empty') ? "" : tags.val()),
      'activity[running]': 'true'
    };
    $.post('/activities', data, function(data, status) {
      if (data && !data.errors) {
        updateUI(data);
        form.find('.activity-name').val('').blur();
        form.find('.activity-tags').val('').blur();
      }
    }, 'json');
  });

  $('#new-activity-form .activity-name').focus(function() {
    var obj = $(this);
    if (obj.val() == "Activity") {
      obj.val('');
    }
    obj.removeClass('empty');
  }).blur(function() {
    var obj = $(this);
    if (!obj.val()) {
      obj.val('Activity');
      obj.addClass('empty');
    }
  }).blur();

  $('#new-activity-form .activity-tags').focus(function() {
    var obj = $(this);
    if (obj.val() == "Tags") {
      obj.val('');
    }
    obj.removeClass('empty');
  }).blur(function() {
    var obj = $(this);
    if (!obj.val()) {
      obj.val('Tags');
      obj.addClass('empty');
    }
  }).blur();

  $('#activity-dialog').dialog({
    autoOpen: false,
    width: 'auto',
    title: 'Add earlier activity',
    buttons: {
      "Cancel": function() {
        $(this).dialog('close');
      },
      "Save": function() {
        $(this).find('form').submit();
      }
    }
  }).find('form').submit(function(e) {
    e.preventDefault();
    f.parent().dialog('close');
  }).find('input').keydown(function(e) {
    if (e.keyCode == 13) {
      $(this).closest('form').submit();
    }
  });

  $('.stop-tracking').live('click', function(e) {
    e.preventDefault();
    $.get('/activities/current/stop', function(data) {
      updateUI(data);
    }, 'json')
  });

  $('#add-earlier-activity').click(function(e) {
    var button = $(this);
    var popup = window.open("/activities/new", '_blank');
    /*
    var popupInterval = setInterval(function() {
      if (popup.closed) {
        clearTimeout(popupInterval);
        button.attr('disabled', false);
      }
    }, 200);
    */
  });

  var resizeTimer = null;
  $(window).bind('resize', function() {
    if (resizeTimer) clearTimeout(resizeTimer);
    resizeTimer = setTimeout(resizeUI, 100);
  });
  resizeUI();

  $('button').button();
  buttonWidth = $('.start-tracking span').width();
  $('.stop-tracking span').width(buttonWidth);

  $('.activity .ui-icon-pencil').live('click', function(e) {
    var icon = $(this);
    var activityId = icon.closest('.activity').attr('class').match(/activity-(\d+)/)[1];
    var popup = window.open("/activities/" + activityId + "/edit", '_blank');
  });

  var confirmationDialog = $('#confirmation-dialog').dialog({
    autoOpen: false,
    resizable: false,
    modal: true,
    buttons: {
      "Delete": function() {
        var obj = $(this);
        var activityId = obj.data('activityId');
        $.get("/activities/" + activityId + "/delete", function(data) {
          updateUI(data);
        }, 'json');
        obj.dialog( "close" );
      },
      Cancel: function() {
        $(this).dialog( "close" );
      }
    }
  });

  $('.activity .ui-icon-trash').live('click', function(e) {
    var icon = $(this);
    var activityId = icon.closest('.activity').attr('class').match(/activity-(\d+)/)[1];
    confirmationDialog.data('activityId', activityId).dialog('open'); });

  var updateInterval = setInterval(updateCurrent, 60000);
});
