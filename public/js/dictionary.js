function Dictionary(attr) {
  this.attr = typeof(attr) == 'undefined' ? null : attr;
  this.entries = {all: []};
}

Dictionary.prototype.getObjectString = function(object) {
  return (this.attr ? object[this.attr] : object).toLowerCase();
}

Dictionary.prototype.add = function(object) {
  var str = this.getObjectString(object);
  return this._add(this.entries, str, 0, object);
};

/* Recursive method to prevent duplicate items from being added
 *
 * NOTE: This does shallow comparisons, so different objects will always
 * be "different" */
Dictionary.prototype._add = function(entries, str, index, object) {
  var result;
  if (index < str.length) {
    var c = str.charAt(index);
    if (!entries.hasOwnProperty(c)) {
      entries[c] = {all: []};
    }
    result = this._add(entries[c], str, index + 1, object);
  }
  else {
    /* Check to see if we've recorded this value yet. */
    result = (entries.all.indexOf(object) == -1);
  }

  if (result) {
    entries.all.push(object);
  }
  return result;
}

Dictionary.prototype.remove = function(object) {
  var str = this.getObjectString(object);
  return this._remove(this.entries, str, 0, object);
}

/* Same thing as _add, except remove :) */
/* DO IT! */
Dictionary.prototype._remove = function(entries, str, index, object) {
  var result;
  if (index < str.length) {
    var c = str.charAt(index);
    if (!entries.hasOwnProperty(c)) {
      return false;
    }
    else {
      result = this._remove(entries[c], str, index + 1, object);
      if (result) {
        if (entries[c].all.length == 0) {
          /* prune! */
          delete entries[c];
        }

        var index = entries.all.indexOf(object);
        entries.all.splice(index, 1);
      }
      return result;
    }
  }
  else {
    /* Check to see if the value's in the dictionary. */
    var index = entries.all.indexOf(object);
    if (index >= 0) {
      entries.all.splice(index, 1);
      return true;
    }
    else {
      return false;
    }
  }
}

Dictionary.prototype.match = function(str) {
  var cur = this.entries;
  var all = cur.all;
  var str = str.toLowerCase();
  for (var i = 0; i < str.length; i++) {
    var c = str.charAt(i);
    if (!cur.hasOwnProperty(c)) {
      return null;
    }
    all = cur[c].all;
    cur = cur[c];
  }
  return all;
}
