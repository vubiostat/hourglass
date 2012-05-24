var activities, tags, projects;

function getActivities() {
  $.get('/activities', function(data) {
    var d = new Dictionary();
    $.each(data, function(i, object) {
      d.add(object);
    });
    activities = d;
  }, 'json');
}

function getTags() {
  $.get('/tags', function(data) {
    var d = new Dictionary();
    $.each(data, function(i, name) {
      d.add(name);
    });
    tags = d;
  }, 'json');
}

function splitTags(val) {
  return val.split(/,\s*/);
}

function extractLastTag(term) {
  return splitTags(term).pop();
}

function getProjects() {
  $.get('/projects', function(data) {
    var d = new Dictionary();
    $.each(data, function(i, name) {
      d.add(name);
    });
    projects = d;
  }, 'json');
}

$(function() {
  // these return immediately
  getActivities();
  getTags();
  getProjects();

  $('input.activity-name').autocomplete({
    minLength: 0,
    delay: 0,
    source: function(request, response) {
      var result = [];
      var parts = request.term.split('@');
      if (parts.length == 2) {
        if (projects != null) {
          var values = projects.match(parts[1]);
          if (values != null) {
            result = values;
          }
        }
      }
      else {
        if (activities != null) {
          var values = activities.match(request.term);
          if (values != null) {
            result = values;
          }
        }
      }
      response(result);
    },
    focus: function(event, ui) {
      var item = ui.item;
      var itemParts = item.value.split('@');
      var obj = $(event.target);
      var objParts = obj.val().split('@');

      if (objParts.length == 2 && itemParts.length == 1) {
        /* autocomplete only the project */
        obj.val(objParts[0] + '@' + item.value);
      }
      else {
        obj.val(item.value);
      }

      return false;
    },
    select: function(event, ui) {
      return false;
    }
  });

  $('#select-activity').click(function(e) {
    $('input.activity-name').focus().autocomplete('search', '');
    e.preventDefault();
  });

  $('input.activity-tags')
    // don't navigate away from the field on tab when selecting an item
    .bind("keydown", function(event) {
      if (event.keyCode === $.ui.keyCode.TAB && $(this).data("autocomplete").menu.active) {
        event.preventDefault();
      }
    })
    .autocomplete({
      minLength: 0,
      delay: 0,
      source: function(request, response) {
        var result = [];
        var term = extractLastTag(request.term);
        if (tags != null) {
          var values = tags.match(term);
          if (values != null) {
            result = values;
          }
        }
        response(result);
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      select: function(event, ui) {
        var terms = splitTags(this.value);

        // remove the current input
        terms.pop();

        // add the selected item
        terms.push(ui.item.value);

        // add placeholder to get the comma-and-space at the end
        terms.push("");

        this.value = terms.join(", ");
        return false;
      }
    });

  var times = []
  for (var h = 0; h < 24; h++) {
    if (h < 10) {
      times.push('0'+h+':00', '0'+h+':15', '0'+h+':30', '0'+h+':45');
    }
    else {
      times.push(h+':00', h+':15', h+':30', h+':45');
    }
  }
  $('.activity-started-at-date, .activity-ended-at-date').datepicker();
  var timeInputs = $('.activity-started-at-time, .activity-ended-at-time').autocomplete({
    minLength: 0,
    delay: 0,
    source: function(request, response) {
      response(times);
      /* get the closest time and highlight it */
      var parts = request.term.split(":");
      if (parts[1]) {
        var min;
        if (parts[1].length == 1) {
          min = parseInt(parts[1]) * 10;
        }
        else if (parts[1].substr(0, 1) == "0") {
          min = parseInt(parts[1].substr(1, 1));
        }
        else {
          min = parseInt(parts[1]);
        }
        min = Math.round(min / 15) * 15;

        if (min == 0) {
          parts[1] = '00';
        }
        else {
          parts[1] = min;
        }
      }
      else {
        parts[1] = '00';
      }
      var target = parts.join(':');
      var index = times.indexOf(target);
      if (index >= 0) {
        this.menu.activate(new $.Event('mouseover'),
          this.menu.element.find('li:nth-child('+(index+1)+')'));
      }
    },
  }).each(function() {
    $(this).data('autocomplete').menu.element.addClass('activity-time');
  });
});
