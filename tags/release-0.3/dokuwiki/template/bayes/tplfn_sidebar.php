<?php 
/*
 * Provide navigation sidebar functionality to Dokuwiki Templates
 *
 * This is not currently part of the official Dokuwiki release
 *
 * @link   http://wiki.jalakai.co.uk/dokuwiki/doku.php?id=tutorials:dev:navigation_sidebar
 * @author Christopher Smith <chris@jalakai.co.uk>
 * @author Riccardo Govoni <battlehorse@gmail.com> 
 */

// sidebar configuration settings
$conf['sidebar']['page'] = tpl_getConf('bayes_sidebar_name');         // name of sidebar page


function tpl_sidebar() {
  global $conf;
  renderBar($conf['sidebar']['page'], true);
}


// display the sidebar
function renderBar($page, $fallbackToIndex = false) {
	global $ID, $REV;
	
	// save globals
	$saveID = $ID;
	$saveREV = $REV;

	$fileSidebar = getBarFN(getNS($ID), $page);

	// determine what to display
	if ($fileSidebar) {
		$ID = $fileSidebar;
		$REV = '';
		print p_wiki_xhtml($ID,$REV,false);
	}
	elseif ($fallbackToIndex){
        global $IDX;
        html_index($IDX);
	}
		
	// restore globals
	$ID = $saveID;
	$REV = $saveREV;
}

// recursive function to establish best sidebar file to be used
function getBarFN($ns, $file) {

	// check for wiki page = $ns:$file (or $file where no namespace)
	$nsFile = ($ns) ? "$ns:$file" : $file;
	if (file_exists(wikiFN($nsFile)) && auth_quickaclcheck($nsFile)) return $nsFile;
	
  // remove deepest namespace level and call function recursively
	
	// no namespace left, exit with no file found	
	if (!$ns) return '';
	
	$i = strrpos($ns, ":");
	$ns = ($i) ? substr($ns, 0, $i) : false;	
	return getBarFN($ns, $file);
}

?>
