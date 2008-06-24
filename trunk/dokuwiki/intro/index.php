<?php
  require_once("accept-to-gettext.inc");
  
  $langs=array('it.ISO-8859-1','it.UTF-8','en_US.UTF-8','en_GB.UTF-8','en.UTF-8', 'en.ISO-8859-1', 'en_US.ISO-8859-1');
  $locale=al2gt($langs, 'text/html');
  
  if (substr($locale,0,2) == 'it') {
    include('index.it.php');
  } else {
    include('index.en.php');
  }
?>