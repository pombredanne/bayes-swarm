function breakdown(url) {
	new Ajax.Updater($("breakdown"),url, {
		onComplete: function(){ initLytebox(); }
		});
}