var lang_code = 'en';
var lang_name = 'English';
function locale() {
  return {lang_code: lang_code, lang_name: lang_name};
}
var translations = {
  'visualization_timeout': 'This visualization is taking a long time, please wait...',
  'visualization_unspecified_error': 'Unspecified error.',
  'visualization_error_occurred': 'An error occurred: ',
  'visualization_retry': 'Retry this analysis.',
  
  'visualization_title': '{0} of {1} ({2})',
  'visualization_title_date': 'From <b>{0}</b> to <b>{1}</b>',
  'visualization_title_source_kind': 'On Source <b>{0}</b> limited to kind <b>{1}</b>',
  'visualization_title_kind': 'Limited to kind <b>{0}</b>',
  
  'language_label': 'Language:',
  'language_italian': 'Italian',
  'language_english': lang_name,   // must be lang_name for the Word field to be ok.

  'word_label': 'Topics:',  
  'word_description': 'Type the topics you\'re interested in, using commas to separate them.',
  
  'source_label': 'Source:',
  'source_all': 'All',
  
  'daterange_from_label': 'From:',
  'daterange_to_label': 'To:',
  'datepicker_dayNames': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  'datepicker_dayNamesMin': ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
  'datepicker_dayNamesShort': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  'datepicker_monthNames': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  'datepicker_monthNamesShort': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  'datepicker_firstDay': 0,
  
  'entity_label': 'Found in:',
  'entity_type_count': 'Overall count',
  'entity_type_heading': 'Headlines',
  'entity_type_anchor': 'Anchors',
  'entity_type_title': 'Page titles',
  'entity_type_body': 'Body occurrences',
  'entity_type_keyword': 'Keywords',
  
  'kind_label': 'Kind:',
  'kind_type_rss': "&nbsp;RSS Feed",
  'kind_type_page': "&nbsp;Webpage",
  'kind_type_both': "&nbsp;Both",
  'kind_type_both_long': 'both Rss Feeds and Webpages',  
  
  'action_csv_export': 'Export as CSV',
  'action_google_news': 'Google News search',
  'action_data_table': 'View Data table',
  'action_media_pie': 'View Media Pie',
  
  'timeserie_title': 'Trends',
  'timeserie_description': 'Analyze time series and study how topics changed over time.',
  
  'stackedchart_title': 'Media Coverage',
  'stackedchart_description': 'Take a look at how different media and news sources paid attention to the topics you are interested in.',
  
  'piechart_title': 'Popularity',
  'piechart_description': 'See what topics are most popular comparing them against each other.',
  
  'motionchart_title': 'News in Motion',
  'motionchart_description': 'Watch the evolution of news topics over time and see how they spread from one media outlet to the other',
  
  'masterform_choose_graph_type': 'Choose a graph type:',
  'masterform_select_icon': 'Select one of the above icons',
  'masterform_parameters': '<b>{0}</b> parameters:',
  'masterform_analyse': 'Analyse!',
  'masterform_direct_csv': 'or export directly to CSV',
  
  'analysis_loading': 'Loading...',
  'analysis_actions_title': 'Actions'
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