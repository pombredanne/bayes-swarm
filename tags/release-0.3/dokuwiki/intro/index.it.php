<?php
  header('Content-Type: text/html; charset=utf-8');
  define(DOKU_INC, dirname(__FILE__).'/wiki/');
  define(DOKU_BASE, "http://www.bayesfor.eu/wiki/");
  define(DOKU_TPL, DOKU_BASE . "lib/tpl/bayes/");
    
  require_once("wiki/inc/init.php");
  require_once("wiki/inc/auth.php");
  require_once("wiki/inc/parserutils.php");

  $entries = 3;

  function cmp_filetime_reverse($first, $second) {
   return $second - $first;
  }
  
  function compose_news_item($pagename, $mtime, $news_item) {
    // dirty hack to modify width of embedded imgs
    $composed_item =  str_replace("width=\"500\"", "width=\"200\"", $news_item); 
    $composed_item = "<hr/>".$composed_item."<p style=\"text-align:right\"> <a href=\"".DOKU_BASE.$pagename."\">Leggi ancora...</a>";
    
    return $composed_item;
  }

  $files = array();
  $dir = "./wiki/".$conf['savedir']."/pages/blog/";
  if ($handle = @opendir($dir)) {
   while (false !== ($file = readdir($handle))) {
     $files[$file] = filemtime($dir.$file);
   }
   uasort($files, "cmp_filetime_reverse");

   $latest_news = "";
   $count = 0;
   foreach($files as $file => $mtime) {
     if ($count == $entries) {
       break;
     }
     if (strcmp(".",$file) != 0 && strcmp("..", $file) != 0) {
       $pagename = "blog:".str_replace(".txt","",$file);
       $title = $pagename;
       $news_item = p_wiki_xhtml_summary($pagename, &$title);
     
       $latest_news .= compose_news_item($pagename, $mtime, $news_item);
       $count++;
     }
   }
   closedir($handle);
  }
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
	<title>BayesFor :: Bayesian web spidering</title>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
  <link rel="stylesheet" href="<?php echo DOKU_TPL; ?>layout.css" type="text/css" media="screen" charset="utf-8" />
  <link rel="stylesheet" href="<?php echo DOKU_TPL; ?>design.css" type="text/css" media="screen" charset="utf-8" /> 
  <link rel="stylesheet" href="css/intro.css" type="text/css" media="screen" charset="utf-8" /> 
  <link rel="shortcut icon" href="favicon.ico" />
	<script src="javascripts/rounded_corners.js" type="text/javascript"></script>
	<script type="text/javascript">
	  window.onload = function()
	  {
	    settings = {
	      tl: { radius: 20 },
	      tr: { radius: 20 },
	      bl: { radius: 20 },
	      br: { radius: 20 },
	      antiAlias: true,
	      autoPad: false
	    }

	    var divObj = document.getElementById("news");

	    var cornersObj = new curvyCorners(settings, divObj);
	    cornersObj.applyCornersToAll();
	  }	
	</script>
</head>
<body>
	<table border="0" cellspacing="0" cellpadding="0" >
		<tr valign="top">
			<td>
				<div class="bayes-header bayes-intro-header">
					<h1>BayesFor.eu</h1><span class="bayes-beta">beta</span>
					<h2>Bayesian web spidering</h2>
				</div>
			</td>
			<td>
				<div class="bayes-header">
					<div id="whoweare">
							<b>BayesFor</b> &egrave; un'associazione di ricercatori che si propone di  promuovere la comprensione e l'uso delle  statistiche. BayesFor realizza ricerche, analisi e consulenze in differenti campi di ricerca applicata.		
					</div>				
				</div>
			</td>
		</tr>
	</table>
	<table border="0" cellspacing="0" cellpadding="0" style="margin-top: 0.5em; margin-bottom: 2em" >
		<tr valign="top">
			<td style="width:300px">
				<img src="./images/bayes_logo.png" style="margin-top: 30px" id="bayes_logo" alt="BayesFor logo">
				<p style="padding: 0em 1em; font-size: 75%; color: #888; line-height: 1.2">
					<em>''statistics is the art of never having to say you are wrong'' </em>
					&nbsp; &nbsp; -- C. J. Bradfield
				</p>
			</td>
			<td style="padding-right: 3em" >
				<table border="0"  >
					<tr valign="top">
						<td class="tt"><a href="<?php echo DOKU_BASE."team" ?>"><img src="./images/button3.png" style="border:0" alt="Team icon"></a> </td>
						<td class="uu" ><h2 class="team"><a href="<?php echo DOKU_BASE."team" ?>">Il Team</a></h2>
							<ul class="headlines team">
								<li><a href="<?php echo DOKU_BASE."team" ?>">A proposito di noi. Chi siamo, cosa facciamo</a></li>
								<li><a href="<?php echo DOKU_BASE."manifest" ?>">Manifesto. Ci&ograve; in cui crediamo</a></li>
								<li><a href="<?php echo DOKU_BASE."collabora_con_noi" ?>">Collabora con noi. Vuoi aiutare?</a></li>
								<li><a href="<?php echo DOKU_BASE."contatti" ?>">Contattaci</a></li>								
							</ul>								
						</td>
					</tr><tr valign="top">
						<td class="tt"><a href="<?php echo DOKU_BASE."projects" ?>"><img src="./images/button1.png" style="border:0" alt="Project icon"></a></td>
						<td class="uu"><h2 class="project"><a href="<?php echo DOKU_BASE."projects" ?>">I progetti</a></h2>
							<ul class="headlines project">
								<li><a href="<?php echo DOKU_BASE."bayes-swarm" ?>">Bayes-Swarm: Data out of the unexpected!</a></li>
								<li><a href="<?php echo DOKU_BASE."network" ?>">Web content network analysis</a></li>
								<li><a href="<?php echo DOKU_BASE."osservatorio" ?>">Osservatorio Politica online</a></li>
							</ul>															
						</td>
					</tr><tr valign="top">	
						<td class="tt"><a href="<?php echo DOKU_BASE ?>"><img src="./images/button2.png" style="border:0" alt="Docs icon"></a></td>
						<td class="uu"><h2 class="docs"><a href="<?php echo DOKU_BASE ?>">I Documenti</a></h2>
							<ul class="headlines docs">
                <li><a href="<?php echo DOKU_BASE ?>">Wiki: &egrave; tutto qui dentro, da qualche parte.</a></li>											  
								<li><a href="<?php echo DOKU_BASE."blog" ?>">Notizie e blog del team</a></li>								
								<li><a href="<?php echo DOKU_BASE."bayes-swarm/documentazione" ?>">Bayes-Swarm: dalle basi ai concetti avanzati</a></li>
								<li><a href="<?php echo DOKU_BASE."attivita" ?>">Attivit&agrave; e pubblicazioni</a></li>								
								<li><a href="<?php echo DOKU_BASE."corsolinux/home" ?>">Materiale corso linux</a></li>
							</ul>																						
					    </td>
					</tr>
				</table>
			</td>
			<td>
				<div id="news">
					<div id="newsheader">
						<h1>Ultime notizie</h1><span class="archive"><a href="<?php echo DOKU_BASE."blog" ?>">consulta l'archivio</a></span>
						<div id="newscontent">						
						  <?php echo $latest_news; ?>
						</div>
					</div>
				</div>
			</td>
		</tr>
	</table>
	<div class="bayes-footer">
	  <?php @include(dirname(__FILE__).'/wiki/lib/tpl/bayes/footer.html') ?>
	</div>
</body>
</html>