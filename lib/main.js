/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

var $tabs = require('thunderbird/tabs'),
    $menus = require('thunderbird/menus'),
    $gloda = require('thunderbird/gloda'),
    $self = require('self');

$tabs.defineTabType({
  name: 'contact-history-vis',
  url: $self.data.url('processing.html'),
  onTabOpened: function(tab, args) {
    tab.title = "Top Contacts IDE";

    let doc = tab.contentDocument;
    let win = doc.defaultView;

    /**
     * Show the results for a contact.  We already have these, so it's a simple
     *  matter of grabbing them out of the history results.
     */
    win.showGlodaSearchTabsForContact = function(contactInfo) {
      let fromTab =
        $tabs.openTab('glodaFacet',
                      { collection: contactInfo.fromMeCollection });
      // XXX failure to localize for now... the gloda attrs have usable things
      //  we can use, however.
      fromTab.title = 'To ' + contactInfo.contact.name;
      // ugh, I did not actually test the collection argument when authoring the
      //  tab.
      fromTab._tabInfo.query = fromTab._tabInfo.collection.query;
      let toTab =
        $tabs.openTab('glodaFacet', { collection: contactInfo.toMeCollection });
      toTab.title = 'From ' + contactInfo.contact.name;
      toTab._tabInfo.query = toTab._tabInfo.collection.query;
    };

    let codeString = $self.data.load('pde-scripts/volvox-inspired.pde');

    // kick off the query
    win.contactResults = [];
    if (args.who === 'top') {
      $gloda.getTopContactsWithPersonalHistory({
        onHistoryAvailable: function(contactResults) {
          win.contactResults = contactResults;
          parseAndGo();
          /*
          if (("p" in tab) && tab.p)
            tab.p.setupData(contactResults);
          */
        }
      });
    }

    function stopProcessing() {
      let canvas = doc.getElementById("canvas");
      if (("p" in tab) && tab.p) {
        tab.p.exit();
        tab.p = null;
      }
      if (canvas)
        canvas.parentNode.removeChild(canvas);
    }

    function parseAndGo() {
      stopProcessing();

      let width = Math.min(win.innerWidth, 1200),
                  height = Math.min(win.innerHeight, 1200);

      let canvas = doc.createElement("canvas");
      canvas.setAttribute("id", "canvas");
      canvas.setAttribute("width", width);
      canvas.setAttribute("height", height);
      let canvasHolder = doc.getElementById("canvasHolder");
      canvasHolder.appendChild(canvas);

      let sizeString = "int WIDTH = " + width + "; int HEIGHT = " +
                       height + "; ";

      tab.p = new win.Processing(canvas, sizeString + codeString);
      // let logging reuse jetpack's console implementation, why not
      tab.p.logger = console;
      tab.p.setupData(win.contactResults);
    }
  },
  onTabClosed: function(tab) {
    if (("p" in tab) && tab.p) {
      tab.p.exit();
      tab.p = null;
    }
  },
  onTabVisible: function(tab) {
    // restore focus to our tab
    tab.contentDocument.activeElement.focus();
    tab.p.loop();
  },
  onTabHidden: function(tab) {
    if (tab.p)
      tab.p.noLoop();
  },
});

$menus.add('mail:3pane', 'tools', {
  label: "Visualize Top Contact History",
  onCommand: function() {
    $tabs.openTab("contact-history-vis", { who: 'top' });
  },
});

/*
$menus.add('mail:3pane', 'otherActions', {
  label: "Visualize Contact Histories",
  command: function(msgHdr) {
    $tabs.openTab("contact-history-vis", { who: msgHdr });
  },
});
*/
