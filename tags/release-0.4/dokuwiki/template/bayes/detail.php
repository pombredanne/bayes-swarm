<?php
/**
 * BayesFor template
 *
 * This is a specialized dokuwiki template especially tailored
 * for the needs of BayesFor.
 *
 * This file is used to display image details
 *
 * @link   http://www.bayesfor.eu
 * @author Riccardo Govoni <battlehorse@gmail.com>
 */

// must be run from within DokuWiki
if (!defined('DOKU_INC')) die();

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php echo $conf['lang']?>" lang="<?php echo $conf['lang']?>" dir="ltr">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>
     <?php echo hsc(tpl_img_getTag('IPTC.Headline',$IMG))?>
    [<?php echo strip_tags($conf['title'])?>]
  </title>

  <?php tpl_metaheaders()?>

  <link rel="shortcut icon" href="<?php echo DOKU_TPL?>images/favicon.ico" />
</head>
<body>
	<div class="bayes-header">
		<div class="bayes-header-logo-bar">
			<h1><?php tpl_link(wl(),'BayesFor.eu','name="dokuwiki__top" id="dokuwiki__top" accesskey="h" title="[ALT+H]"')?></h1><span class="bayes-beta">beta</span>
			<h2>Bayesian web spidering</h2>
		</div>
	</div>  
  
  <div class="bayes-main" >
  	<div class="bayes-sidebar">
        <h2>Caption</h2>
        <p class="img_caption">
          <?php print nl2br(hsc(tpl_img_getTag(array('IPTC.Caption',
                                                 'EXIF.UserComment',
                                                 'EXIF.TIFFImageDescription',
                                                 'EXIF.TIFFUserComment'),"No caption available"))); ?>
        </p>
        <?php //Comment in for Debug// dbg(tpl_img_getTag('Simple.Raw'));?>
      <h2>Details</h2>
      <dl class="img_tags">
        <?php
          $t = tpl_img_getTag('Date.EarliestTime');
          if($t) print '<p><b>'.$lang['img_date'].':</b> '.strftime($conf['dformat'],$t).'</p>';

          $t = tpl_img_getTag('File.Name');
          if($t) print '<p><b>'.$lang['img_fname'].':</b> '.hsc($t).'</p>';

          $t = tpl_img_getTag(array('Iptc.Byline','Exif.TIFFArtist','Exif.Artist','Iptc.Credit'));
          if($t) print '<p><b>'.$lang['img_artist'].':</b> '.hsc($t).'</p>';

          $t = tpl_img_getTag(array('Iptc.CopyrightNotice','Exif.TIFFCopyright','Exif.Copyright'));
          if($t) print '<p><b>'.$lang['img_copyr'].':</b> '.hsc($t).'</p>';

          $t = tpl_img_getTag('File.Format');
          if($t) print '<p><b>'.$lang['img_format'].':</b> '.hsc($t).'</p>';

          $t = tpl_img_getTag('File.NiceSize');
          if($t) print '<p><b>'.$lang['img_fsize'].':</b> '.hsc($t).'</p>';

          $t = tpl_img_getTag('Simple.Camera');
          if($t) print '<p><b>'.$lang['img_camera'].':</b> '.hsc($t).'</p>';

          $t = tpl_img_getTag(array('IPTC.Keywords','IPTC.Category'));
          if($t) print '<p><b>'.$lang['img_keywords'].':</b> '.hsc($t).'</p>';

        ?>
      </dl>	  
  	</div>
		<div class="bayes-breadcrumbs">
		  <table cellspacing="0" cellpadding="0" border="0">
		    <tr valign="top"><td width="100%">
        Image Details: <?php echo hsc($IMG) ?>      
		    </td></tr></table>
		</div>  	
    <div class="bayes-main-contents">
      <?php html_msgarea()?>

      <?php if($ERROR){ print $ERROR; }else{ ?>

        <h1><?php echo hsc(tpl_img_getTag('IPTC.Headline',$IMG))?></h1>
        <p>&larr; <?php echo $lang['img_backto']?> <?php tpl_pagelink($ID)?></p>

        <div class="img_big">
          <?php tpl_img(900,700) ?>
        </div>
        
        <p>&larr; <?php echo $lang['img_backto']?> <?php tpl_pagelink($ID)?></p>
        
      <?php } ?>
    </div>
  </div>
</body>
</html>

