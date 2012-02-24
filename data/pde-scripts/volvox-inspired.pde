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

color overlayBgColor = color(255, 255, 255, 128);
color overlayBorderColor = color(192, 192, 192, 128);
color overlayTextColor = color(0, 0, 0, 255);
int FONT_SIZE = 20;
PFont fontA = loadFont("Arial");
textFont(fontA, FONT_SIZE);
textAlign(CENTER, CENTER);

int RING_MARGIN = 40;
int MAX_CX = WIDTH / 2 - RING_MARGIN;
int MAX_CY = HEIGHT / 2 - RING_MARGIN;
int MAX_VX = 1;
int MAX_VY = 1;

Object overContact = null;

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

  if ((cx - outerR) < nmouseX &&
      (cx + outerR) > nmouseX &&
      (cy - outerR) < nmouseY &&
      (cy + outerR) > nmouseY) {
    overContact = contactInfo;
    stroke(focusedLineColor);
  }
  else {
    stroke(lineColor);
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
  popMatrix();
}

void drawOverlay(contactInfo) {
  int tw = textWidth(contactInfo.contact.name);

  fill(overlayBgColor);
  stroke(overlayBorderColor);
  rect(contactInfo.cx - (tw / 2) - 4, contactInfo.cy - (FONT_SIZE / 2) - 2,
       tw + 8, FONT_SIZE + 4);

  fill(overlayTextColor);
  text(contactInfo.contact.name, contactInfo.cx, contactInfo.cy);

  stroke(lineColor);
}

void draw() {
  background(255, 255);
  pushMatrix();
  translate(width / 2, height / 2);
  nmouseX = mouseX - width / 2;
  nmouseY = mouseY - height / 2;

  overContact = null;
  for (int i=0; i < contactInfoArr.length; i++) {
    drawContact(contactInfoArr[i]);
  }
  if (overContact) {
    drawOverlay(overContact);
  }

  popMatrix();
}

void mouseClicked() {
  if (overContact) {
    showGlodaSearchTabsForContact(overContact);
  }
}
