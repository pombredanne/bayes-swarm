<?php
 
if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');
 
class syntax_plugin_bayes_reflexify extends DokuWiki_Syntax_Plugin { 
 
  function getInfo(){
      return array(
          'author' => 'Riccardo Govoni',
          'email'  => 'battlehorse@gmail.com',
          'date'   => '2008-06-23',
          'name'   => 'BayesFor Reflexify plugin',
          'desc'   => 'Adds reflex effect to images',
          'url'    => 'http://www.bayesfor.eu',
      );
  }


  function getType(){ return 'substition'; }
  function getPType(){ return 'block'; }
  function getSort(){ return 999; }

  function connectTo($mode) {
    $this->Lexer->addSpecialPattern('~~REFLEX .*?~~',$mode,'plugin_bayes_reflexify'); 
  }

  function handle($match, $state, $pos, &$handler){
    $match = substr($match, 9, -2); // strip "~~REFLEX " from the beginning and "~~" from the end
    $img_and_options = explode(" ", $match);
    if (sizeof($img_and_options) > 0) {
      $img = $img_and_options[0];
    }
    if (sizeof($img_and_options) > 1) {
      $options = implode(",", array_slice($img_and_options, 1));
    }
    return array($img, $options);
  }

  function render($mode, &$renderer, $indata) {
    if($mode == 'xhtml'){
      if ($indata[1]) {
        $renderer->doc .= "<script>bayes_reflexify('$indata[0]',{ $indata[1] });</script>";        
      } else {
        $renderer->doc .= "<script>bayes_reflexify('$indata[0]');</script>";        
      }

      return true;
    }
    return false;
  }
}
