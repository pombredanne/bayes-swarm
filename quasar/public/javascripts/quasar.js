// namespaces
quasar = {};
quasar.action = {};
quasar.form = {};
quasar.model = {};
quasar.analysis = {};

// Global variables
// ****************

// Keeps track of the analysis currently shown in the page
var currentLayout = [];

// Global functions
// ****************

quasar.icon = function(iconname) {
  return $('<div />').addClass('ui-state-default ui-corner-all qs-icon-box').
    append($("<span />").addClass('ui-icon ui-icon-' + iconname + ' qs-icon')).
    hover(
  		function() { $(this).addClass('ui-state-hover'); }, 
  		function() { $(this).removeClass('ui-state-hover'); }
  	);;
};

quasar.formatDate = function(date) {
  return '' + date.getFullYear() + '/' + (date.getMonth() +1) + '/' + date.getDate();
};

quasar.gvizUrl = function() {
  var params = [];
  $.each(this.models, function(name, model) {
    params.push(model.params());
  });
  return root_path + this.gvizPrefix + '?' + params.join('&');
};

quasar.visualizationTitle = function() {
  var title_div = $('<div />');
  $('<h2 />').text(t('visualization_title', [this.models.entity.to_s(), this.models.word.to_s(), this.models.word.language])).appendTo(title_div);
  var txt = t('visualization_title_date', [quasar.formatDate(this.models.date.from_date), quasar.formatDate(this.models.date.to_date)]);
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  
  var txt = '';
  if (this.models.source) {
    txt = t('visualization_title_source_kind', [this.models.source.to_s(), this.models.kind.to_s()]);
  } else {
    txt = t('visualization_title_kind', [this.models.kind.to_s()]);
  }
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;
};

quasar.timelineResponse = function(container, redo_function) {
  return function(response) {
    if (!quasar.initResponseArea(response, container, redo_function)) {
      return;
    }

    var data = response.getDataTable();
    var graph_container = $("<div style='width: 600px; height: 200px;'/>").appendTo(container);
    var chart = new google.visualization.AnnotatedTimeLine(graph_container.get(0));
    chart.draw(data);
  };
};

quasar.tableResponse = function(container, redo_function) {
  return function(response) {
    if (!quasar.initResponseArea(response, container, redo_function)) {
      return;
    }

    var data = response.getDataTable();
    var chart = new google.visualization.Table(container.get(0));
    chart.draw(data);
  };  
};

quasar.barChartResponse = function(container, redo_function) {
  return function(response) {
    if (!quasar.initResponseArea(response, container, redo_function)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.BarChart(container.get(0));
    chart.draw(data, {width: 500, height: 350, is3D: true, isStacked: true, axisFontSize: 12, legendFontSize: 10 });
  };
};

quasar.pieChartResponse = function(container, redo_function) {
  return function(response) {
    if (!quasar.initResponseArea(response, container, redo_function)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.PieChart(container.get(0));
    chart.draw(data, {width: 300, height: 300, is3D: true, pieJoinAngle: 5, legendFontSize: 10 });
  };
};

quasar.motionChartResponse = function(container, redo_function) {
  return function(response) {
    if (!quasar.initResponseArea(response, container, redo_function)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.MotionChart(container.get(0));
    chart.draw(data, {width: 600, height: 400});
  };
};

quasar.initResponseArea = function(response, container, redo_function) {
  container.empty();
  if (response.isError()) {
    var timeout = false;
    var errorReasons = response.getReasons()
    for (var i = 0, l = errorReasons.length; i < l; i++) {
      if (errorReasons[i] == 'timeout') {
        timeout = true;
        break;
      }
    }
    if (timeout) {
      container.append($('<span>' + t('visualization_timeout') + '</span>'));
    } else {
      var message = response.getDetailedMessage() || response.getMessage() || t('visualization_unspecified_error');
      container.append($('<span />').html(t('visualization_error_occurred') + message));
      
      var retry_link = $('<span class="qs-link" />').text(t('visualization_retry'));
      retry_link.click(function() { redo_function(); });
      container.append($('<br />')).append(retry_link);
    }
  }
  return !response.isError();
};

// Fields
// ****************

quasar.form.Word = function() {
  this.language = locale().lang_name;
  this.lang_code = locale().lang_code;
};
quasar.form.Word.prototype.render = function(container) {
  var that = this;
  $("<span>" + t('language_label') + "</span>").appendTo(container);  
  var it_checked = this.lang_code == 'it'? 'checked' : '';
  this.it_input = $("<input type='radio' name='language' value='it' " + it_checked + ">");
  $("<label />").append(this.it_input).append('&nbsp;' + t('language_italian')).appendTo(container);
  this.it_input.click(function (){
    that.language = t('language_italian');
    that.lang_code = 'it';    
    that.buildAc('it', ac_label);
  });

  var en_checked = this.lang_code == 'en'? 'checked' : '';
  this.en_input = $("<input type='radio' name='language' value='en' " + en_checked + ">");
  $("<label />").append(this.en_input).append('&nbsp;' + t('language_english')).appendTo(container);  
  this.en_input.click(function (){
    that.language = t('language_english');
    that.lang_code = 'en';        
    that.buildAc('en', ac_label);    
  });
  $('<br />').appendTo(container);
  var ac_label = $("<span>" + t('word_label') + "</span>").appendTo(container);
  this.buildAc(this.lang_code, ac_label);
  $("<span class='qs-hint' />").
    text(t('word_description')).
    appendTo(container);
};
quasar.form.Word.prototype.buildAc = function(lang, placeHolder) {
  var old_ac = this.intword_ac;
  if (old_ac) {
    old_ac.remove();
  }
  that = this;
  this.intword_ac = $("<input name='q' type='text' style='width: 300px' />").insertAfter(placeHolder);
  this.intword_ac.autocomplete({
    serviceUrl: root_path + "intword/ac",
    minChars: 2,
    width: 300,
    params: {lang: lang},
    delimiter: /,\s*/
  });
};
quasar.form.Word.prototype.toModel = function() {
  this.intword_names = $.map(this.intword_ac.val().split(','), 
                             function(name) { return $.trim(name); });
  return new quasar.model.Word(this.intword_names, this.language, this.lang_code);
};
quasar.model.Word = function(intword_names, language, lang_code) {
  this.intword_names = intword_names;
  this.language = language;
  this.lang_code = lang_code;
};
quasar.model.Word.prototype.params = function() {
  return 'id=' + this.intword_names.join(',') + '&language=' + this.lang_code ;
};
quasar.model.Word.prototype.to_s = function() {
  return this.intword_names.join(',');
};

quasar.form.Source = function() {};
quasar.form.Source.prototype.render = function(container) {
  $("<span>" + t('source_label') + "</span>").appendTo(container);
  source_select = $('<select />').appendTo(container);
  $.each(sources, function(i, source) {   // 'sources' global variable hack
    $("<option value='" + source.id + "'>" + source.name + "</option>").appendTo(source_select);
  });
  this.source_select = source_select;
};
quasar.form.Source.prototype.toModel = function() {
  return new quasar.model.Source(this.source_select.val(),
                                 this.source_select.find(':selected').text());
};
quasar.model.Source = function(selected_val, selected_text) {
  this.selected_val = selected_val;
  this.selected_text = selected_text;
};
quasar.model.Source.prototype.params = function() {
  return 'source=' + this.selected_val;
};
quasar.model.Source.prototype.to_s = function() {
  return this.selected_text;
};

quasar.form.DateRange = function() {};
quasar.form.DateRange.prototype.render = function(container) {
  $("<span>" + t('daterange_from_label') + "</span>").appendTo(container);
  this.from_date_dp = $("<input type='text' />").appendTo(container).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true,
      dayNames: t('datepicker_dayNames'), dayNamesMin: t('datepicker_dayNamesMin'),
      dayNamesShort: t('datepicker_dayNamesShort'),
      monthNames: t('datepicker_monthNames'), monthNamesShort: t('datepicker_monthNamesShort'),
      firstDay: t('datepicker_firstDay')
    });
  $("<span>&nbsp;&nbsp;</span>").appendTo(container);
  $("<span>" + t('daterange_to_label') + "</span>").appendTo(container);
  this.to_date_dp = $("<input type='text' />").appendTo(container).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true,
      dayNames: t('datepicker_dayNames'), dayNamesMin: t('datepicker_dayNamesMin'),
      dayNamesShort: t('datepicker_dayNamesShort'),
      monthNames: t('datepicker_monthNames'), monthNamesShort: t('datepicker_monthNamesShort'),
      firstDay: t('datepicker_firstDay')
    });  
};
quasar.form.DateRange.prototype.from_date = function() {
  var one_month_ago = new Date();
  one_month_ago.setMonth(one_month_ago.getMonth()-1);
  var from_date = this.from_date_dp.datepicker('getDate') || one_month_ago;
  return from_date;
};
quasar.form.DateRange.prototype.to_date = function() {
  var today = new Date();
  var to_date = this.to_date_dp.datepicker('getDate') || today;  
  return to_date;
};
quasar.form.DateRange.prototype.toModel = function() {
  return new quasar.model.DateRange(this.from_date(), this.to_date());
};
quasar.model.DateRange = function(from_date, to_date) {
  this.from_date = from_date;
  this.to_date = to_date;
};
quasar.model.DateRange.prototype.params = function() {
  return 'from_date=' + quasar.formatDate(this.from_date) + '&to_date=' + quasar.formatDate(this.to_date);
};

quasar.form.Entity = function() {};
quasar.form.Entity.prototype.render = function(container) {
  $("<span>" + t('entity_label') + "</span>").appendTo(container);
  this.entity_select = $('<select />').appendTo(container);
  $("<option value='count'>" + t('entity_type_count') + "</option>").appendTo(this.entity_select);
  $("<option value='headingcount'>" + t('entity_type_heading') + "</option>").appendTo(this.entity_select);
  $("<option value='anchorcount'>" + t('entity_type_anchor') + "</option>").appendTo(this.entity_select);
  $("<option value='titlecount'>" + t('entity_type_title') + "</option>").appendTo(this.entity_select);  
  $("<option value='bodycount'>" + t('entity_type_body') + "</option>").appendTo(this.entity_select);
  $("<option value='keywordcount'>" + t('entity_type_keyword') + "</option>").appendTo(this.entity_select);
};
quasar.form.Entity.prototype.toModel = function() {
  return new quasar.model.Entity(this.entity_select.val(),
                                 this.entity_select.find(':selected').text());
};
quasar.model.Entity = function(selected_val, selected_text) {
  this.selected_val = selected_val;
  this.selected_text = selected_text;
}
quasar.model.Entity.prototype.params = function() {
  return 'entity=' + this.selected_val;
};
quasar.model.Entity.prototype.to_s = function() {
  return this.selected_text;
};

quasar.form.Kind = function() {};
quasar.form.Kind.prototype.render = function(container) {
  $("<span>" + t('kind_label') + "</span>").appendTo(container);
  this.rss_input = $("<input type='radio' name='kind' value='rss'>");
  $("<label />").append(this.rss_input).append(t('kind_type_rss')).appendTo(container);
  this.url_input = $("<input type='radio' name='kind' value='url'>");
  $("<label />").append(this.url_input).append(t('kind_type_page')).appendTo(container);
  this.both_input = $("<input type='radio' name='kind' value='both' checked>");
  $("<label />").append(this.both_input).append(t('kind_type_both')).appendTo(container);  
};
quasar.form.Kind.prototype.toModel = function() {
  var kind_val = null;
  var kind_text = null;
  if (this.rss_input.is(':checked')) {
    kind_val = 'rss';
    kind_text = t('kind_type_rss');
  } else if (this.url_input.is(':checked')) {
    kind_val = 'url';
    kind_text = t('kind_type_page');
  } else {
    kind_val = 'both';
    kind_text = t('kind_type_both_long');
  }
  return new quasar.model.Kind(kind_val, kind_text);
};
quasar.model.Kind = function(kind_val, kind_text) {
  this.kind_val = kind_val;
  this.kind_text = kind_text;
};
quasar.model.Kind.prototype.params = function() {
  return 'kind=' + this.kind_val;
};
quasar.model.Kind.prototype.to_s = function() {
  return this.kind_text;
};

// Actions
// ****************

quasar.action.CsvLink = function(csv_url) {
  return $("<a href='" + csv_url + "' />").text(t('action_csv_export'));
};
quasar.action.GoogleNewsArchive = function(intword_names, lang_code, from_date, to_date) {
  var news_search_link = 'http://news.google.com/archivesearch?' + 
    'as_user_ldate=' + quasar.formatDate(from_date) +
    '&as_user_hdate=' + quasar.formatDate(to_date) +
    '&lr=lang_' + lang_code + '&hl=' + lang_code +
    '&q=' + intword_names.join('+');
  return $("<a href='" + news_search_link + "' target='_blank' />").text(t('action_google_news'));  
};
quasar.action.GetDataTable = function(gvizPrefix, models) {
  var action = $("<span class='qs-link' />").text(t('action_data_table')).click(function (){
    var analysis = new quasar.analysis.DataTable(gvizPrefix);
    var container = $('#analysis_container');  // TODO: the container id shouldn't be hardcoded
    quasar.createAnalysis(container, analysis, models);
  });
  return action;
};
quasar.action.MediaPie = function(models) {
  var action = $("<span class='qs-link' />").text(t('action_media_pie')).click(function (){
    var analysis = new quasar.analysis.MediaPieChart();
    var container = $('#analysis_container');  // TODO: the container id shouldn't be hardcoded
    quasar.createAnalysis(container, analysis, models);
  });
  return action;  
};

// quasar.action.Permalink = function(permalink_url, type) {
//   return $("<a href='" + permalink_url + '&type=' + type + "' />").text("Permalink");
// };

// Analysis : DataTable
// This is a 'lite' visualization, since it lacks the logic to display its own
// form, back can only be invoked with an existing set of Models.
// ****************
quasar.analysis.DataTable = function(gvizPrefix) {
  this.gvizPrefix = gvizPrefix;
};
quasar.analysis.DataTable.prototype.callback = quasar.tableResponse;
quasar.analysis.DataTable.prototype.url = quasar.gvizUrl;
quasar.analysis.DataTable.prototype.visualizationTitle = quasar.visualizationTitle;
quasar.analysis.DataTable.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/ts','/intword/show'), 'ts'),
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0')];
};

// Analysis : TimeSeries
// ****************

quasar.analysis.TimeSeries = function() {
  this.gvizPrefix = 'gviz/ts';
  this.icon = image_path + 'trends.png';
  this.title = t('timeserie_title');
  this.description = t('timeserie_description');
};
quasar.analysis.TimeSeries.prototype.createFields = function() {
  return [
    {name: 'word', instance: new quasar.form.Word()},
    {name: 'date', instance: new quasar.form.DateRange()},
    {name: 'entity', instance: new quasar.form.Entity()},
    {name: 'source', instance: new quasar.form.Source()},
    {name: 'kind', instance: new quasar.form.Kind()}
  ];
};
quasar.analysis.TimeSeries.prototype.callback = quasar.timelineResponse;
quasar.analysis.TimeSeries.prototype.url = quasar.gvizUrl;
quasar.analysis.TimeSeries.prototype.visualizationTitle = quasar.visualizationTitle;
quasar.analysis.TimeSeries.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/ts','/intword/show'), 'ts'),
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.models.word.intword_names, 
                                           this.models.word.lang_code,             
                                           this.models.date.from_date,
                                           this.models.date.to_date),
           quasar.action.GetDataTable(this.gvizPrefix, this.models)];
};

// Analysis : Stacked
// ****************

quasar.analysis.StackedChart = function() {
  this.gvizPrefix = 'gviz/stacked';
  this.icon = image_path + 'mediacoverage.png';
  this.title = t('stackedchart_title');
  this.description = t('stackedchart_description');
};
quasar.analysis.StackedChart.prototype.createFields = function() {
  return [
    {name:'word', instance: new quasar.form.Word()},
    {name:'date', instance: new quasar.form.DateRange()},
    {name:'entity', instance: new quasar.form.Entity()},
    {name:'kind', instance: new quasar.form.Kind()}
  ];
};
quasar.analysis.StackedChart.prototype.callback = quasar.barChartResponse;
quasar.analysis.StackedChart.prototype.url = quasar.gvizUrl;
quasar.analysis.StackedChart.prototype.visualizationTitle = quasar.visualizationTitle;
quasar.analysis.StackedChart.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/wordpie','/intword/show'), 'wordpie'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.models.word.intword_names,
                                           this.models.word.lang_code,
                                           this.models.date.from_date,
                                           this.models.date.to_date),
           quasar.action.GetDataTable(this.gvizPrefix, this.models),
           quasar.action.MediaPie(this.models)];
};

// Analysis : PieChart
// ****************

quasar.analysis.PieChart = function() {
  this.gvizPrefix = 'gviz/wordpie';
  this.icon = image_path + 'popularity.png';
  this.title = t('piechart_title');
  this.description = t('piechart_description');
};
quasar.analysis.PieChart.prototype.createFields = function() {
  return [
    {name: 'word', instance: new quasar.form.Word()},
    {name: 'date', instance: new quasar.form.DateRange()},
    {name: 'entity', instance: new quasar.form.Entity()},
    {name: 'source', instance: new quasar.form.Source()},
    {name: 'kind', instance: new quasar.form.Kind()}
  ];
};
quasar.analysis.PieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.PieChart.prototype.url = quasar.gvizUrl;
quasar.analysis.PieChart.prototype.visualizationTitle = quasar.visualizationTitle;
quasar.analysis.PieChart.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/wordpie','/intword/show'), 'wordpie'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.models.word.intword_names,
                                           this.models.word.lang_code,
                                           this.models.date.from_date,
                                           this.models.date.to_date),
           quasar.action.GetDataTable(this.gvizPrefix, this.models) ];
};

// Analysis : MediaPieChart
// ****************

quasar.analysis.MediaPieChart = function() {
  this.gvizPrefix = 'gviz/pagepie';
};
quasar.analysis.MediaPieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.MediaPieChart.prototype.url = quasar.gvizUrl;
quasar.analysis.MediaPieChart.prototype.visualizationTitle = quasar.visualizationTitle;
quasar.analysis.MediaPieChart.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/pagepie','/intword/show'), 'pagepie'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.models.word.intword_names, 
                                           this.models.word.lang_code,             
                                           this.models.date.from_date,
                                           this.models.date.to_date),
           quasar.action.GetDataTable(this.gvizPrefix, this.models) ];
};

// Analysis : MotionChart
// ****************

quasar.analysis.MotionChart = function() {
  this.gvizPrefix = 'gviz/motion';
  this.icon = image_path + 'motion.png';
  this.title = t('motionchart_title');
  this.description = t('motionchart_description');
};
quasar.analysis.MotionChart.prototype.createFields = function() {
  return [
    {name: 'word', instance: new quasar.form.Word()},
    {name: 'date', instance: new quasar.form.DateRange()},
    {name: 'entity', instance: new quasar.form.Entity()},
    {name: 'kind', instance: new quasar.form.Kind()}
  ];
};
quasar.analysis.MotionChart.prototype.callback = quasar.motionChartResponse;
quasar.analysis.MotionChart.prototype.url = quasar.gvizUrl;
quasar.analysis.MotionChart.prototype.visualizationTitle = quasar.visualizationTitle;
quasar.analysis.MotionChart.prototype.actions =  function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/motion','/intword/show'), 'motion'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.models.word.intword_names, 
                                           this.models.word.lang_code,             
                                           this.models.date.from_date,
                                           this.models.date.to_date),
           quasar.action.GetDataTable(this.gvizPrefix, this.models) ];
};


// Global functions (again?)
// ****************
quasar.createMasterForm = function(form_container, analysis_container) {
  var formDiv = $("<div class='qs-form' style='display:none'></div>");
  $("<p>" + t('masterform_choose_graph_type') + "</p>").appendTo(formDiv);
  var formControlsDiv = $("<div class='qs-form-controls' ></div>");
  formControlsDiv.text(t('masterform_select_icon'));
  quasar.createAnalysisForm(formDiv, formControlsDiv, analysis_container, new quasar.analysis.TimeSeries());
  quasar.createAnalysisForm(formDiv, formControlsDiv, analysis_container, new quasar.analysis.PieChart());
  quasar.createAnalysisForm(formDiv, formControlsDiv, analysis_container, new quasar.analysis.StackedChart());
  quasar.createAnalysisForm(formDiv, formControlsDiv, analysis_container, new quasar.analysis.MotionChart());
  $("<div id='qs-chart-description' style='display:none'></div>").appendTo(formDiv);
  $("<br clear='both' />").appendTo(formDiv);
  formControlsDiv.appendTo(formDiv);
  form_container.empty().append(formDiv);
  formDiv.fadeIn('fast');
};

quasar.createAnalysisForm = function(formDiv, formControlsDiv, analysis_container, analysis) {
  var chart = $("<div class='qs-chart' />").appendTo(formDiv);
  chart.append($("<img src='" + analysis.icon + "'>"));
  chart.click(function() {
    $('.qs-chart').removeClass('qs-chart-selected');
    $(this).addClass('qs-chart-selected');
    formControlsDiv.fadeOut('fast').empty();
    formControlsDiv.append('<p>' + t('masterform_parameters', [analysis.title]) + '</p>');
    var fields = analysis.createFields();
    quasar.createFormFields(formControlsDiv, fields);

    var submit_btn = $("<button id='qs-analysis-btn' />").text(t('masterform_analyse'));
    submit_btn.appendTo(formControlsDiv);
    submit_btn.click(function() {
      var models = {};
      $.each(fields, function(i, field) { 
        models[field.name] = field.instance.toModel();
      });
      quasar.createAnalysis(analysis_container, analysis, models);
    });
    
    var direct_csv_link = $("<a class='qs-link-csv' href='#'></a>").text(t('masterform_direct_csv'));
    direct_csv_link.appendTo(formControlsDiv);
    direct_csv_link.click(function(evt) {
      evt.stopPropagation();
      var models = {};
      $.each(fields, function(i, field) { 
        models[field.name] = field.instance.toModel();
      });
      quasar.grabCsv(analysis, models);
    })
    
    formControlsDiv.fadeIn('fast');
  });
  chart.hover(function() {
    quasar.createDescription($('#qs-chart-description'), analysis);
  }, function() {
    $('#qs-chart-description').hide().empty();
  });
};

quasar.createDescription = function(descriptionDiv, analysis) {
  $('<p><strong>' + analysis.title + '</strong></p>').appendTo(descriptionDiv);
  $('<p>' + analysis.description + '</p>').appendTo(descriptionDiv);
  descriptionDiv.show();
};

quasar.createFormFields = function(formControlsDiv, fields) {
  $.each(fields, function(i, field) {
    var fieldDiv = $('<div class="qs-form-control" />').appendTo(formControlsDiv);
    field.instance.render(fieldDiv);
  });
};

quasar.grabCsv = function(analysis, models) {
  analysis.models = models;
  var csvUrl = analysis.url() + '&tqx=out:csv%3BreqId:0';
  document.location.href = csvUrl;  // dirty hack to trigger the CSV download
};

quasar.createAnalysis = function(container, analysis, models) {
  analysis.models = models;
  currentLayout.push(analysis);
  var currentLayoutPos = currentLayout.length-1;
  
  var analysis_div = $("<div class='qs-analysis' style='display:none'/>");
  quasar.icon('close').attr('style', 'float:right').appendTo(analysis_div).click(function() {
    analysis_div.remove();
    currentLayout[currentLayoutPos] = null;
  });
  analysis.visualizationTitle().appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis-graph'></div>").appendTo(analysis_div);
  $("<img src='" + image_path + "spin.gif' alt='" + t('analysis_loading') + "' />").appendTo(graph_div);
  
  var actions_div = $("<div class='qs-analysis-action'></div>").appendTo(analysis_div);
  $('<h3>' + t('analysis_actions_title') + '</h3>').appendTo(actions_div);  
  var actions_list = $("<ul />").appendTo(actions_div);
  
  $.each(analysis.actions(), function(i, action) {
    $("<li />").append(action).appendTo(actions_list);
  });
    
  $("<br clear='both' />").appendTo(analysis_div);
  container.append(analysis_div);
  analysis_div.fadeIn('fast');

  var query = new google.visualization.Query(analysis.url());
  query.setTimeout(15);
  query.send(analysis.callback(graph_div, quasar.redoFunction(graph_div, analysis)));
};

quasar.redoFunction = function(graph_div, analysis) {
  return function() {
    graph_div.empty();
    $("<img src='" + image_path + "spin.gif' alt='" + t('analysis_loading') +"' />").appendTo(graph_div);
    var query = new google.visualization.Query(analysis.url());
    query.setTimeout(15);    
    query.send(analysis.callback(graph_div, quasar.redoFunction(graph_div, analysis)));    
  };
};

