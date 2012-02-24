jetpack.future.import("menu");
jetpack.future.import("thunderbird.tabs");
jetpack.future.import("thunderbird.gloda");

let tb = jetpack.thunderbird;

let exampleScript = <><![CDATA[
/* Volvox-inspired visualization of your top contact history v0.1.
 *  Andrew Sutherland <asutherland@asutherland.org>
 * Released under the MIT license.
 */

void setup() {
  size(640,480);
  frameRate(10);
  strokeWeight(1);
}

float rotation = 0.0;
float rotateStep = TWO_PI / 360;

color baseColor = color(255, 255, 255, 128);
color fromMeColor = color(192, 192, 255, 128);
color toMeColor = color(192, 255, 192, 128);
color lineColor = color(128, 128, 128, 64);
stroke(lineColor);

int RING_MARGIN = 40;
int MAX_CX = width / 2 - RING_MARGIN;
int MAX_CY = height / 2 - RING_MARGIN;
int MAX_VX = 1;
int MAX_VY = 1;

Array contactInfoArr = {};

void setupData(contactInfos) {
  contactInfoArr = contactInfos;
  for (int i=0; i < contactInfos.length; i++) {
    contactInfos[i].rotation = random(TWO_PI);
    contactInfos[i].rotationRate = TWO_PI * random(2) * 0.003;
    contactInfos[i].cx = random(-MAX_CX, MAX_CX);
    contactInfos[i].cy = random(-MAX_CY, MAX_CY);
    contactInfos[i].vx = random(-MAX_VX, MAX_VX);
    contactInfos[i].vy = random(-MAX_VY, MAX_VY);
  }
}

void drawContact(contactInfo) {
  // figure the linear length desired for display and that is our
  //  circumference.  use that to figure out the base radius
  int monthCount = contactInfo.byMonth.length;
  int circumference = (monthCount * 15);
  float baseR = circumference / TWO_PI;

  // - rotation
  float rotation = contactInfo.rotation + contactInfo.rotationRate;
  if (rotation >= TWO_PI)
    rotation = rotation - TWO_PI;
  contactInfo.rotation = rotation;

  // - movement
  float cx = contactInfo.cx + contactInfo.vx;
  if (cx > MAX_CX || cx < -MAX_CX) {
    cx = cx - 2 * contactInfo.vx;
    contactInfo.vx = -contactInfo.vx;
  }
  contactInfo.cx = cx;

  flaot cy = contactInfo.cy + contactInfo.vy;
  if (cy > MAX_CY || cy < -MAX_CY) {
    cy = cy - 2 * contactInfo.vy;
    contactInfo.vy = -contactInfo.vy;
  }
  contactInfo.cy = cy;
  pushMatrix();
  translate(cx, cy);


  float startAng;
  float endAng;
  float lipSize = 4.0;
  float outerR = baseR + lipSize;
  float innerR = baseR - lipSize;

  for (int i=0; i < monthCount; i++) {
    Object month = contactInfo.byMonth[i];
    int fromMeCount = month.fromMe.length;
    int toMeCount = month.toMe.length;

    startAng = i * TWO_PI / monthCount + rotation;
    endAng = (i + 1) * TWO_PI / monthCount + rotation;

    float outerCR = outerR + toMeCount * 2 + lipSize;
    color curToColor = lerpColor(baseColor, toMeColor,
                         constrain(float(toMeCount) / 8, 0.0, 1.0));
    fill(curToColor);
    beginShape();
    vertex(baseR * cos(startAng), baseR * sin(startAng));
    vertex(outerR * cos(startAng), outerR * sin(startAng));
    bezierVertex(outerCR * cos(startAng), outerCR * sin(startAng),
                 outerCR * cos(endAng), outerCR * sin(endAng),
                 outerR * cos(endAng), outerR * sin(endAng));
    vertex(baseR * cos(endAng), baseR * sin(endAng));
    bezierVertex(outerR * cos(endAng), outerR * sin(endAng),
                 outerR * cos(startAng), outerR * sin(startAng),
                 baseR * cos(startAng), baseR * sin(startAng));
    endShape(CLOSE);

    float innerCR = innerR - fromMeCount * 2 + lipSize - 1;
    color curFromColor = lerpColor(baseColor, fromMeColor,
                           constrain(float(fromMeCount) / 8, 0.0, 1.0));
    fill(curFromColor);
    beginShape();
    vertex(baseR * cos(startAng), baseR * sin(startAng));
    vertex(innerR * cos(startAng), innerR * sin(startAng));
    bezierVertex(innerCR * cos(startAng), innerCR * sin(startAng),
                 innerCR * cos(endAng), innerCR * sin(endAng),
                 innerR * cos(endAng), innerR * sin(endAng));
    vertex(baseR * cos(endAng), baseR * sin(endAng));
    bezierVertex(outerR * cos(endAng), outerR * sin(endAng),
                 outerR * cos(startAng), outerR * sin(startAng),
                 baseR * cos(startAng), baseR * sin(startAng));
    endShape(CLOSE);
  }
  popMatrix();
}

void draw() {
  background(255);
  pushMatrix();
  translate(width / 2, height / 2);

  for (int i=0; i < contactInfoArr.length; i++) {
    drawContact(contactInfoArr[i]);
  }

  popMatrix();
}
]]></>.toString();

tb.tabs.defineTabType({
  name: "top-contact-history",
  onTabOpened: function(tab, args) {
    tab.title = "Top Contacts IDE";

    let doc = tab.contentDocument;
    let win = doc.defaultView;;

    doc.getElementById("code").value = exampleScript;

    // kick off the query
    win.contactResults = [];
    tb.gloda.getTopContactsWithPersonalHistory({
      onHistoryAvailable: function(contactResults) {
        win.contactResults = contactResults;
        if (("p" in tab) && tab.p)
          tab.p.setupData(contactResults);
      }
    });

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
      let codeString = doc.getElementById("code").value;
      stopProcessing();

      let canvas = doc.createElement("canvas");
      canvas.setAttribute("id", "canvas");
      canvas.setAttribute("width", "640");
      canvas.setAttribute("height", "480");
      let canvasHolder = doc.getElementById("canvasHolder");
      canvasHolder.appendChild(canvas);
      tab.p = win.Processing(canvas, codeString);
      tab.p.setupData(win.contactResults);
    }

    doc.getElementById("reparse").addEventListener("click", parseAndGo, false);
    doc.getElementById("stop").addEventListener("click", stopProcessing, false);
  },
  html: <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <style type="text/css"><![CDATA[
        body {
          background-color: #ffffff;
          padding: 4px;
        }
      ]]></style>
      <script type="application/javascript" src="resource://jetpack/content/js/processing.js"/>
    </head>
    <body>
      <div id="canvasHolder">
      </div>
      <button type="button" id="reparse">Update and Go</button>
      <button type="button" id="stop">Stop!</button><br />
      <textarea id="code" rows="60" cols="80">
      </textarea>
    </body>
  </html>
});

jetpack.menu.tools.add({
  label: "Visualize Top Contact History",
  command: function() tb.tabs.openTab("top-contact-history", {})
});
