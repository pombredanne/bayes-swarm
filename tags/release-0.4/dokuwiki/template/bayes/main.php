<?php
/**
 * BayesFor template
 *
 * This is a specialized dokuwiki template especially tailored
 * for the needs of BayesFor.
 *
 * @link   http://www.bayesfor.eu
 * @author Riccardo Govoni <battlehorse@gmail.com>
 */

// must be run from within DokuWiki
if (!defined('DOKU_INC')) die();

// include functions that provide sidebar functionality
@require_once(dirname(__FILE__).'/tplfn_sidebar.php');

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php echo $conf['lang']?>"
 lang="<?php echo $conf['lang']?>" dir="<?php echo $lang['direction']?>">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>
    <?php echo strip_tags($conf['title'])?> :: <?php tpl_pagetitle()?>
  </title>

  <?php tpl_metaheaders()?>
  <link rel="shortcut icon" href="<?php echo DOKU_TPL?>images/favicon.ico" />  
</head>
<body>
	<div class="bayes-header">
	  <div class="bayes-header-logo"></div>
		<div class="bayes-header-logo-bar">
			<h1><?php tpl_link(wl(),'BayesFor.eu','name="dokuwiki__top" id="dokuwiki__top" accesskey="h" title="[ALT+H]"')?></h1><span class="bayes-beta">beta</span>
			<h2>Bayesian web spidering</h2>
		</div>
		<div class="bayes-header-tab-bar">
			<ul class="bayes-tabs">
				<li class="bayes-tab-selected"><a href="http://www.bayesfor.eu">BayesFor</a></li>
				<li><a href="http://www.bayes-swarm.com">Swarm</a></li>
				<li><a href="http://code.google.com/p/bayes-swarm">Code</a></li>
			</ul>
		</div>
	</div>
	
	<div class="bayes-main dokuwiki" >
			<div class="bayes-sidebar">
        <?php
        $translation = &plugin_load('syntax','translation');
        echo $translation->_showTranslations();
        ?>
        <br clear="both"/>			  
			  <?php tpl_sidebar()?>
			</div>
			<div class="bayes-breadcrumbs">
			  <table cellspacing="0" cellpadding="0" border="0">
			    <tr valign="top"><td width="100%">
        <?php if($conf['breadcrumbs']){?>
          <?php tpl_breadcrumbs()?>
        <?php }?>

        <?php if($conf['youarehere']){?>
          <?php tpl_youarehere() ?>
        <?php }?>			  
         </td><td style="white-space: nowrap">
        <div class="bayes-search">
    			    <?php tpl_searchform()?> 
    			  </div>        
			  </td></tr></table>
		  </div>
		  <div class="bayes-main-contents">
		    <div class="bayes-userinfo">
		      <?php tpl_userinfo()?> ::
          <?php tpl_actionlink('admin')?>
          <?php tpl_actionlink('profile')?>
          <?php tpl_actionlink('login')?>		      
		    </div>
			  <?php tpl_content()?>
			</div>
	</div>
  <?php flush()?>
	
  <div class="bayes-actions">
    <div style="text-align: right; float: right">
      <?php tpl_actionlink('top')?> ::	
      <?php tpl_pageinfo()?>                					      
    </div>
    <?php tpl_actionlink('edit')?>
    <?php tpl_actionlink('history')?>
    <?php tpl_actionlink('recent')?>
    <?php tpl_actionlink('subscription')?>
    <?php tpl_actionlink('index')?>
  </div>	
	
	<div class="bayes-footer">
	  <?php @include(dirname(__FILE__).'/footer.html') ?>

	</div>
	<div class="no"><?php tpl_indexerWebBug()?></div>
</body>
</html>