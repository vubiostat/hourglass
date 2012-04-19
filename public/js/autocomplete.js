var activities;
var tags;

function getActivities() {
  $.get('/activities', function(data) {
    var d = new Dictionary('activity_name');
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

$(function() {
  getActivities();  // returns immediately
  getTags();

  $('input.activity-name').autocomplete({
    minLength: 0,
    delay: 0,
    source: function(request, response) {
      var result = [];
      if (activities != null) {
        var values = activities.match(request.term);
        if (values != null) {
          result = values;
        }
      }
      response(result);
    },
    focus: function(event, ui) {
      var item = ui.item;
      var activityName = $(event.target);

      var str = item.activity_name;
      if (item.project_name) {
        str += "@" + item.project_name;
      }
      activityName.val(str);

      return false;
    },
    select: function(event, ui) {
      var item = ui.item;
      var activityName = $(event.target);

      var str = item.activity_name;
      if (item.project_name) {
        str += "@" + item.project_name;
      }
      activityName.val(str);

      return false;
    }
  }).data( "autocomplete" )._renderItem = function(ul, item) {
    var str = item.activity_name;
    if (item.project_name) {
      str += "@" + item.project_name;
    }
    return $("<li></li>")
    .data("item.autocomplete", item)
    .append("<a>" + str + "</a>")
    .appendTo(ul);
  };

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
});
