/* Volvox-inspired visualization of your top contact history v0.1.
 *  Andrew Sutherland <asutherland@asutherland.org>
 * Released under the MIT license.
 */

void setup() {
  size(WIDTH, HEIGHT);
  frameRate(10);
  strokeWeight(1);

  MAX_CX = width / 2 - RING_MARGIN;
  MAX_CY = height / 2 - RING_MARGIN;
}

float rotation = 0.0;
float rotateStep = TWO_PI / 360;

color baseColor = color(255, 255, 255, 128);
color fromMeColor = color(192, 192, 255, 128);
color toMeColor = color(192, 255, 192, 128);
color lineColor = color(128, 128, 128, 96);
color focusedLineColor = color(128, 128, 128, 192);
color draggingLineColor = color(128, 128, 192, 192);

color overlayBgColor = color(255, 255, 255, 128);
color overlayFocusedTextColor = color(0, 0, 0, 255);
color overlayUnfocusedTextColor = color(0, 0, 0, 128);
color overlayDraggingTextColor = color(0, 0, 64, 255);
int FONT_FOCUSED_SIZE = 20;
int FONT_UNFOCUSED_SIZE = 14;
PFont fontA = loadFont("Arial");
textFont(fontA, FONT_UNFOCUSED_SIZE);
textAlign(CENTER, CENTER);

int RING_MARGIN = 40;
int MAX_CX = WIDTH / 2 - RING_MARGIN;
int MAX_CY = HEIGHT / 2 - RING_MARGIN;
int MAX_VX = 1;
int MAX_VY = 1;

Object overContact = null;
Object draggingContact = null;

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

int nmouseX;
int nmouseY;

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
  // only move if we are not being dragged
  float cx;
  float cy;
  if (draggingContact != contactInfo) {
    cx = contactInfo.cx + contactInfo.vx;
    if (cx > MAX_CX || cx < -MAX_CX) {
      cx = cx - 2 * contactInfo.vx;
      contactInfo.vx = -contactInfo.vx;
    }
    contactInfo.cx = cx;

    cy = contactInfo.cy + contactInfo.vy;
    if (cy > MAX_CY || cy < -MAX_CY) {
      cy = cy - 2 * contactInfo.vy;
      contactInfo.vy = -contactInfo.vy;
    }
    contactInfo.cy = cy;
  }
  else {
    cx = contactInfo.cx;
    cy = contactInfo.cy;
  }
  pushMatrix();
  translate(cx, cy);

  float startAng;
  float endAng;
  float lipSize = 4.0;
  float outerR = baseR + lipSize;
  float innerR = baseR - lipSize;

  boolean focused;
  if ((cx - outerR) < nmouseX &&
      (cx + outerR) > nmouseX &&
      (cy - outerR) < nmouseY &&
      (cy + outerR) > nmouseY) {
    overContact = contactInfo;
    stroke(focusedLineColor);
    focused = true;
  }
  else {
    stroke(lineColor);
    focused = false;
  }
  if (draggingContact == contactInfo) {
    stroke(draggingLineColor);
  }

  for (int i=0; i < monthCount; i++) {
    Object month = contactInfo.byMonth[i];
    int fromMeCount = month.fromMe.length;
    int toMeCount = month.toMe.length;

    startAng = i * TWO_PI / monthCount + rotation;
    endAng = (i + 1) * TWO_PI / monthCount + rotation;

    float outerCR = outerR + log(toMeCount + 1) * 8 + lipSize;
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

    float innerCR = innerR - log(fromMeCount + 1) * 8 + lipSize - 1;
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


  if (focused) {
    textSize(FONT_FOCUSED_SIZE);
    int tw = textWidth(contactInfo.contact.name);

    fill(overlayBgColor);
    stroke(null);
    rect(-(tw / 2) - 4,
         -(FONT_FOCUSED_SIZE / 2) - 2,
         tw + 8, FONT_FOCUSED_SIZE + 4);
    if (draggingContact == contactInfo)
      fill(overlayDraggingTextColor);
    else
      fill(overlayFocusedTextColor);
  }
  else {
    textSize(FONT_UNFOCUSED_SIZE);
    fill(overlayUnfocusedTextColor);
  }
  text(contactInfo.contact.name, 0, 0);

  popMatrix();
}

void draw() {
  background(255, 255);

  if (draggingContact != null) {
    stroke(0);
    fill(224);
    rect(1, height - 60, 239, 59);
    fill(0);
    textSize(14);
    text("Drop here to show in gloda", 120, height - 30);
  }

  pushMatrix();
  translate(width / 2, height / 2);
  nmouseX = mouseX - width / 2;
  nmouseY = mouseY - height / 2;

  overContact = null;
  for (int i=0; i < contactInfoArr.length; i++) {
    drawContact(contactInfoArr[i]);
  }
  popMatrix();
}

int mouseDeltaX = 0;
int mouseDeltaY = 0;
float funkyVelX = 0;
float funkyVelY = 0;
void mousePressed() {
  nmouseX = mouseX - width / 2;
  nmouseY = mouseY - height / 2;

  funkyVelX = 0;
  funkyVelY = 0;

  if (overContact != null) {
    draggingContact = overContact;
    mouseDeltaX = nmouseX - draggingContact.cx;
    mouseDeltaY = nmouseY - draggingContact.cy;
  }
}
void mouseDragged() {
  if (draggingContact != null) {
    nmouseX = mouseX - width / 2;
    nmouseY = mouseY - height / 2;

    draggingContact.cx = nmouseX - mouseDeltaX;
    draggingContact.cy = nmouseY - mouseDeltaY;

    funkyVelX *= 0.7;
    funkyVelY *= 0.7;
    funkyVelX += mouseX - pmouseX;
    funkyVelY += mouseY - pmouseY;
  }
}
void mouseReleased() {
  if (draggingContact != null) {
    draggingContact.vx = constrain(funkyVelX * 0.08, -6, 6);
    draggingContact.vy = constrain(funkyVelY * 0.08, -6, 6);

    if (mouseX > 0 && mouseX < 240 &&
        mouseY > (height - 60) && mouseY < height) {
      showGlodaSearchTabsForContact(draggingContact);
    }

    draggingContact = null;
  }
}

void mouseClick() {
}
