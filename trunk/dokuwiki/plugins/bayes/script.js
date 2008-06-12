document.write("<script src='" + DOKU_BASE + "lib/plugins/bayes/rounded_corners.inc.js' ></script>");

window.onload = function() {
  settings = {
    tl: { radius: 10 },
    tr: { radius: 10 },
    bl: { radius: 10 },
    br: { radius: 10 },
    antiAlias: true,
    autoPad: false
  };

  var cornersObj = new curvyCorners(settings, "bayes-curvy-box");
  cornersObj.applyCornersToAll();
};