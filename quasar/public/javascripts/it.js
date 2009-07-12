var lang_code = 'it';
var lang_name = 'Italiano';
function locale() {
  return {lang_code: lang_code, lang_name: lang_name};
}
var translations = {
  'visualization_timeout': 'Questa visualizzazione sta richiedendo pi&ugrave; tempo del previsto. Attendere...',
  'visualization_unspecified_error': 'Errore non previsto.',
  'visualization_error_occurred': 'Si &egrave; verificato un errore: ',
  'visualization_retry': 'Riprova questa analisi.',
  
  'visualization_title': '{0} per {1} ({2})',
  'visualization_title_date': 'Dal <b>{0}</b> al <b>{1}</b>',
  'visualization_title_source_kind': 'Sulla fonte <b>{0}</b> limitato al tipo <b>{1}</b>',
  'visualization_title_kind': 'Limitato al tipo <b>{0}</b>',  
  
  'language_label': 'Lingua:',
  'language_italian': lang_name,   // must be lang_name for the Word field to be ok.
  'language_english': 'Inglese',  
  
  'word_label': 'Argomenti:',
  'word_description': 'Digita gli argomenti a cui sei interessato, separandoli con la virgola.',
  
  'source_label': 'Fonte:',
  'source_all': 'Tutte',  
  
  'daterange_from_label': 'Dal:',
  'daterange_to_label': 'Al:',
  'datepicker_dayNames': ['Domenica', 'Luned&igrave;', 'Marted&igrave;', 'Mercoled&igrave;', 'Gioved&igrave;', 'Venerd&igrave;', 'Sabato'],
  'datepicker_dayNamesMin': ['Do', 'Lu', 'Ma', 'Me', 'Gi', 'Ve', 'Sa'],
  'datepicker_dayNamesShort': ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'],
  'datepicker_monthNames': ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'],
  'datepicker_monthNamesShort': ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'],  
  'datepicker_firstDay': 1,  
  
  'entity_label': 'Trovato in:',
  'entity_type_count': 'Occorrenze totali',
  'entity_type_heading': 'Titoli di articoli',
  'entity_type_anchor': 'Hyperlink',
  'entity_type_title': 'Titoli di pagina',
  'entity_type_body': 'Corpo del testo',
  'entity_type_keyword': 'Parole chiave',
  
  'kind_label': 'Tipo:',
  'kind_type_rss': "&nbsp;Feed RSS",
  'kind_type_page': "&nbsp;Pagine web",
  'kind_type_both': "&nbsp;Entrambi",
  'kind_type_both_long': 'sia feed RSS che pagine web',
  
  'action_csv_export': 'Salva come CSV',
  'action_google_news': 'Ricerca su Google News',
  'action_data_table': 'Mostra tabella dati',
  'action_media_pie': 'Raggruppa per fonte media',
  
  'timeserie_title': 'Andamenti',
  'timeserie_description': 'Analizza gli andamenti temporali e studia come cambiano gli argomenti nel tempo.',
  
  'stackedchart_title': 'Copertura dei Media',
  'stackedchart_description': 'Osserva quanto diversi media e testate giornalistische si sono occupate degli argomenti che ti interessano.',
  
  'piechart_title': 'Popolarit&agrave;',
  'piechart_description': 'Guarda quali argomenti sono i pi&ugrave; popolari e comparali l\'uno con l\'altro.',
  
  'motionchart_title': 'Notizie in Movimento',
  'motionchart_description': 'Guarda l\'evoluzione delle notizie nel tempo e osserva come si diffondono da una testata all\'altra.',
  
  'masterform_choose_graph_type': 'Scegli il tipo di analisi:',
  'masterform_select_icon': 'Seleziona una delle icone soprastanti',
  'masterform_parameters': 'Parametri dell\'analisi <b>{0}</b>:',  
  'masterform_analyse': 'Analizza!',
  'masterform_direct_csv': 'o salva direttamente come CSV',
  
  'analysis_loading': 'Raccolta dati...',
  'analysis_actions_title': 'Azioni'
};
function t(transl_key, opt_params) {
  var trans =  translations[transl_key];
  if (opt_params) {
    for (var i=0; i<opt_params.length; i++) {
      trans =  trans.replace('{' + i  + '}', opt_params[i]);
    }
  }
  return trans;
}