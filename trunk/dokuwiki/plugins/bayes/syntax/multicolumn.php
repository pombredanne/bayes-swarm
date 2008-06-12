<?php
 
if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');
 
class syntax_plugin_bayes_multicolumn extends DokuWiki_Syntax_Plugin { 
 
  function getInfo(){
      return array(
          'author' => 'Riccardo Govoni',
          'email'  => 'battlehorse@gmail.com',
          'date'   => '2008-06-02',
          'name'   => 'BayesFor Multicolumn layout',
          'desc'   => 'Creates a multicolumn layout for the BayesFor template',
          'url'    => 'http://code.google.com/p/bayes-swarm',
      );
  }


  function getType(){ return 'substition'; }
  function getPType(){ return 'block'; }
  function getSort(){ return 999; }

  function connectTo($mode) {
    $this->Lexer->addSpecialPattern('~~MULTICOL~~',$mode,'plugin_bayes_multicolumn'); 
    $this->Lexer->addSpecialPattern('~~COL~~',$mode,'plugin_bayes_multicolumn'); 
    $this->Lexer->addSpecialPattern('~~MULTICLOSE~~',$mode, 'plugin_bayes_multicolumn');      
  }

  function handle($match, $state, $pos, &$handler){
    if (strstr($match, "MULTICOL")) {
      return array("opening");
    } elseif (strstr($match, "~~COL~~")) {
      return array("colsep");
    } else {
      return array("closing");
    }
  }

  function render($mode, &$renderer, $indata) {
    if($mode == 'xhtml'){
      if (strcmp($indata[0], "opening") == 0) {
        $renderer->doc .= '<table class="bayes-multicol"><tr valign="top"><td class="bayes-multicol" width="100%">';
      } elseif (strcmp($indata[0], "colsep") == 0) {
        $renderer->doc .= '</td><td class="bayes-multicol">';
      } else {
        $renderer->doc .= "</td></tr></table>";
      }        
      return true;
    }
    return false;
  }
}
