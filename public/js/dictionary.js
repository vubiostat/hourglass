function Dictionary(attr) {
  this.attr = typeof(attr) == 'undefined' ? null : attr;
  this.entries = {all: []};
}

Dictionary.prototype.add = function(object) {
  var str = (this.attr ? object[this.attr] : object).toLowerCase();
  this.entries.all.push(object);

  var cur = this.entries;
  for (var i = 0; i < str.length; i++) {
    var c = str.charAt(i);
    if (!cur.hasOwnProperty(c)) {
      cur[c] = {all: []};
    }
    cur[c].all.push(object);
    cur = cur[c];
  }
};

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
