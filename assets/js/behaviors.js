let behaviors = {
  "tei":{
    "abbr": [
      ["[type=siglum]", ['', ' ']]
    ],
    "gap": [
      ["[unit=lines]", function(elt) {
        let span = document.createElement("span");
        span.innerHTML = this.repeat(
          "<span style=\"display:block;\">*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;*</span>", 
          Number.parseInt(elt.getAttribute("quantity")));
        return span;
      }],
      ["[unit=character]", function(elt) {
        let span = document.createElement("span");
        span.innerHTML = this.repeat("*", Number.parseInt(elt.getAttribute("quantity")));
        return span;
      }],
      ["_", ["<span>*</span>"]]
    ],
    "handDesc": function(e) {
      let result = document.createElement("span");
      if (parseInt(e.getAttribute("hands")) > 1) {
        result.innerHTML = "hands: " + e.innerHTML;
      } else {
        result.innerHTML = "hand: " + e.innerHTML;
      }
      return result;
    },
    "l": function(elt) {
      this.add_anchor(elt);
    },
    "lem": [
      ['div.apparatus tei-lem', [' ']]
    ],
    "note": [
      ["[place=foot]", function(elt) {
        if (!this.noteIndex){
          this["noteIndex"] = 1;
        } else {
          this.noteIndex++;
        }
        let id = "_note_" + this.noteIndex;
        let link = document.createElement("a");
        link.setAttribute("name", "src" + id);
        link.setAttribute("href", "#dest" + id);
        link.innerHTML = this.noteIndex;
        let content = document.createElement("sup");
        content.appendChild(link);
        let notes = document.querySelector("ol.notes");
        if (!notes) {
          const noteDiv = document.createElement('div');
          noteDiv.classList.add('notes');
          notes = document.createElement("ol");
          notes.classList.add("class", "notes");
          noteDiv.appendChild(notes);
          document.querySelector('main').appendChild(noteDiv);
        }
        let note = document.createElement("li");
        note.id = "dest" + id;
        note.innerHTML = `<a href="#${"src" + id}">${this.noteIndex}.</a>` + elt.innerHTML;
        notes.appendChild(note);
        return content;
      }],
      ['tei-app>tei-note', (elt) => {
        if (!elt.innerHTML.match(/^[,;:.]/)) {
          elt.insertAdjacentText('afterbegin', ' ');
        }
      }],
      ["_", []]
    ],
    "p": function(elt) {
      if (elt.hasAttribute("n")) {
        elt.insertAdjacentHTML('afterbegin', "<span class=\"pnum\">" + elt.getAttribute("n") + ".</span>");
      }
    },
    // Overrides the default ptr behavior, displaying a short link
    "ptr": function(elt) {
      var link = document.createElement("a");
      link.innerHTML = elt.getAttribute("target").replace(/https?:\/\/([^\/]+)\/.*/, "$1");
      link.href = elt.getAttribute("target");
      return link;
    },
    "rdg": [
      ['div.apparatus tei-rdg:not(:first-of-type)', [' | ']]
    ],
    "seg": function(elt) {
      elt.insertAdjacentHTML('beforebegin', "<sup>" + elt.getAttribute("n") + " </sup>");
    },
    "supplied": ["&lt;","&gt;"],
    "surplus": ["[","]"],
    "table": function(elt) {
      let table = document.createElement("table");
      table.innerHTML = elt.innerHTML;
      if (table.firstElementChild.localName == "tei-head") {
        let head = table.firstElementChild;
        head.remove();
        let caption = document.createElement("caption");
        caption.innerHTML = head.innerHTML;
        table.appendChild(caption);
      }
      for (let row of Array.from(table.querySelectorAll("tei-row"))) {
        let tr = document.createElement("tr");
        tr.innerHTML = row.innerHTML;
        for (let attr of Array.from(row.attributes)) {
          tr.setAttribute(attr.name, attr.value);
        }
        row.parentElement.replaceChild(tr, row);
      }
      for (let cell of Array.from(table.querySelectorAll("tei-cell"))) {
        let td = document.createElement("td");
        if (cell.hasAttribute("cols")) {
          td.setAttribute("colspan", cell.getAttribute("cols"));
        }
        td.innerHTML = cell.innerHTML;
        for (let attr of Array.from(cell.attributes)) {
          td.setAttribute(attr.name, attr.value);
        }
        cell.parentElement.replaceChild(td, cell);
      }
      this.hideContent(elt, true);
      elt.appendChild(table);
    },
    "witDetail": function(elt) {
      var content = document.createElement("span");
      if (elt.hasAttribute("data-empty")) {
        if (elt.getAttribute("type") == "correction-altered") {
          content.innerHTML = " (p.c.) "
        }
        if (elt.getAttribute("type") == "correction-original") {
          content.innerHTML = " (a.c.) "
        }
      } else {
        content.innerHTML = " " + elt.innerHTML + " ";
      }
      return content;
    }
  },
  "functions": {
    "add_anchor": function(elt) {
      if (elt.hasAttribute("data-citation")) {
        let a = document.createElement("a");
        a.setAttribute("name", elt.getAttribute("data-citation"));
        elt.prepend(a);
      }
    }
  }
};