document.write("<script src='" + DOKU_BASE + "lib/plugins/bayes/rounded_corners.inc.js' ></script>");
document.write("<script src='" + DOKU_BASE + "lib/plugins/bayes/cvi_reflex_lib.js' ></script>");

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

function bayes_reflexify(src, options) {
  var cvi_options = options;
  if (!cvi_options) { 
    cvi_options = { tilt: "right" };
  }
  var imgs = document.getElementsByTagName("IMG");
  for (var i = 0; i < imgs.length; i++) {
    if (imgs[i].src.indexOf(src) != -1) {
      cvi_reflex.add(imgs[i], cvi_options);
    }
  }
}