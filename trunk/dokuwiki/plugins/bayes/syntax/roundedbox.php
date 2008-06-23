<?php
 
if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');
 
class syntax_plugin_bayes_roundedbox extends DokuWiki_Syntax_Plugin {
  
  var $kinds = array(
      'blue' => 'bayes-side-popup-blue',
      'b' => 'bayes-side-popup-blue',
      'yellow'   => 'bayes-side-popup-yellow',
      'y' => 'bayes-side-popup-yellow', 
      'green' => 'bayes-side-popup-green',
      'g'   => 'bayes-side-popup-green'
    );
    
  var $default_kind = 'b';  
 
  function getInfo(){
      return array(
          'author' => 'Riccardo Govoni',
          'email'  => 'battlehorse@gmail.com',
          'date'   => '2008-06-02',
          'name'   => 'BayesFor rounded Boxes',
          'desc'   => 'Creates rounded boxes used in the BayesFor template',
          'url'    => 'http://www.bayesfor.eu',
      );
  }
 
  function getType() { return 'container'; }
  function getAllowedTypes() {return array('container','substition','protected','disabled','formatting','paragraphs'); }
  function getSort(){ return 999; }
 
  function connectTo($mode) {
    $this->Lexer->addEntryPattern('<bayesbox.*?>(?=.*?</bayesbox>)',$mode,'plugin_bayes_roundedbox');
  }
 
  function postConnect() {
    $this->Lexer->addExitPattern('</bayesbox>','plugin_bayes_roundedbox');
  }
 
  function handle($match, $state, $pos, &$handler){
    switch ($state) {
      case DOKU_LEXER_ENTER : 
        $kind = strtolower(trim(substr($match,strlen('<bayesbox'),-1)));
        foreach( $this->kinds as $kw => $class ) {
          if (strcmp($kind,$kw) == 0) {
            return array($state, $class);
          }
        } 
        return array($state, $this->kinds[$this->default_kind]);          

      case DOKU_LEXER_UNMATCHED :
        return array($state, $match);
    
      default:
        return array($state);
    }      
  }
 
  function render($mode, &$renderer, $indata) {
    if($mode == 'xhtml'){
      list($state, $data) = $indata;
      switch ($state) {
        case DOKU_LEXER_ENTER :
          $renderer->doc .= '<div class="'. $data . ' bayes-curvy-box">';
          break;

        case DOKU_LEXER_UNMATCHED :
          $renderer->doc .= hsc($data);
          break;

        case DOKU_LEXER_EXIT :
          $renderer->doc .= "\n</div><div class='bayes-spacer'>&nbsp;</div>";
          break;
      }
      return true;
    }
    return false;
  }
}
