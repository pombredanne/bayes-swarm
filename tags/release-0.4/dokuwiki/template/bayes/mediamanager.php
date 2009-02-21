<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<?php
/**
 * BayesFor template
 *
 * This is a specialized dokuwiki template especially tailored
 * for the needs of BayesFor.
 *
 * This file is used by the media manager popup
 *
 * @link   http://www.bayesfor.eu
 * @author Riccardo Govoni <battlehorse@gmail.com>
 */
?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php echo $conf['lang']?>" lang="<?php echo $conf['lang']?>" dir="ltr">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>
    <?php echo hsc($lang['mediaselect'])?>
    [<?php echo strip_tags($conf['title'])?>]
  </title>
  <?php tpl_metaheaders()?>
  <link rel="shortcut icon" href="<?php echo DOKU_TPL?>images/favicon.ico" />
</head>

<body>
<div id="media__manager" class="bayes-main-contents">
    <div id="media__left">
        <?php html_msgarea()?>
        <h1><?php echo hsc($lang['mediaselect'])?></h1>

        <?php /* keep the id! additional elements are inserted via JS here */?>
        <div id="media__opts"></div>

        <?php tpl_mediaTree() ?>
    </div>

    <div id="media__right">
        <?php tpl_mediaContent() ?>
    </div>
</div>
</body>
</html>
