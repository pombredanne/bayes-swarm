// namespaces
quasar = {};
quasar.action = {};
quasar.form = {};
quasar.model = {};
quasar.analysis = {};

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

quasar.timelineResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();
    var graph_container = $("<div style='width: 600px; height: 200px;'/>").appendTo(container);
    var chart = new google.visualization.AnnotatedTimeLine(graph_container.get(0));
    chart.draw(data);
  };
};

quasar.tableResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();
    var chart = new google.visualization.Table(container.get(0));
    chart.draw(data);
  };  
};

quasar.barChartResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.BarChart(container.get(0));
    chart.draw(data, {width: 500, height: 350, is3D: true, isStacked: true, axisFontSize: 12, legendFontSize: 10 });
  };
};

quasar.pieChartResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.PieChart(container.get(0));
    chart.draw(data, {width: 300, height: 300, is3D: true, pieJoinAngle: 5, legendFontSize: 10 });
  };
};

quasar.motionChartResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.MotionChart(container.get(0));
    chart.draw(data, {width: 600, height: 400});
  };
};

quasar.initResponseArea = function (response, container) {
  container.empty();
  if (response.isError()) {
    var timeout = false;
    errorReasons = response.getReasons()
    for (var i = 0, l = errorReasons.length; i < l; i++) {
      if (errorReasons[i] == 'timeout') {
        timeout = true;
        break;
      }
    }
    if (timeout) {
      container.append($('<span class="qs-description">This visualization is taking a long time, please wait...</span>'));
    } else {
      container.append($('<span class="qs-description" />').text('Error in query: ' + response.getMessage()));
    }
  }
  return !response.isError();
};

// Fields
// ****************

quasar.form.Word = function() {
  this.language = 'English';
  this.lang_code = 'en';
};
quasar.form.Word.prototype.render = function(container) {
  var that = this;
  $("<span>Language:</span>").appendTo(container);  
  this.it_input = $("<input type='radio' name='language' value='it'>");
  $("<label />").append(this.it_input).append("&nbsp;Italian").appendTo(container);
  this.it_input.click(function (){
    that.language = 'Italian';
    that.lang_code = 'it';    
    that.buildAc('it', ac_label);
  });

  this.en_input = $("<input type='radio' name='language' value='en' checked>");
  $("<label />").append(this.en_input).append("&nbsp;English").appendTo(container);  
  this.en_input.click(function (){
    that.language = 'English';
    that.lang_code = 'en';        
    that.buildAc('en', ac_label);    
  });
  $('<br />').appendTo(container);
  var ac_label = $("<span>Word:</span>").appendTo(container);
  this.buildAc('en', ac_label);
  $("<span class='qs-hint' />").
    text("Type the topics you're interested in, using commas to separate them.").
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
  $("<span>Source:</span>").appendTo(container);
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
  $("<span>From:</span>").appendTo(container);
  this.from_date_dp = $("<input type='text' />").appendTo(container).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });
  $("<span>&nbsp;&nbsp;</span>").appendTo(container);
  $("<span>To:</span>").appendTo(container);
  this.to_date_dp = $("<input type='text' />").appendTo(container).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });  
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
  $("<span>Found in:</span>").appendTo(container);
  this.entity_select = $('<select />').appendTo(container);
  $("<option value='count'>Overall count</option>").appendTo(this.entity_select);
  $("<option value='headingcount'>Headings</option>").appendTo(this.entity_select);
  $("<option value='anchorcount'>Anchors</option>").appendTo(this.entity_select);
  $("<option value='titlecount'>Titles</option>").appendTo(this.entity_select);  
  $("<option value='bodycount'>Body occurrences</option>").appendTo(this.entity_select);
  $("<option value='keywordcount'>Keywords</option>").appendTo(this.entity_select);
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
  $("<span>Kind:</span>").appendTo(container);
  this.rss_input = $("<input type='radio' name='kind' value='rss'>");
  $("<label />").append(this.rss_input).append("&nbsp;RSS Feed").appendTo(container);
  this.url_input = $("<input type='radio' name='kind' value='url'>");
  $("<label />").append(this.url_input).append("&nbsp;Webpage").appendTo(container);
  this.both_input = $("<input type='radio' name='kind' value='both' checked>");
  $("<label />").append(this.both_input).append("&nbsp;Both").appendTo(container);  
};
quasar.form.Kind.prototype.toModel = function() {
  var kind_val = null;
  var kind_text = null;
  if (this.rss_input.is(':checked')) {
    kind_val = 'rss';
    kind_text = 'Rss Feed';
  } else if (this.url_input.is(':checked')) {
    kind_val = 'url';
    kind_text = 'Webpage';
  } else {
    kind_val = 'both';
    kind_text = 'both Rss Feeds and Webpages';
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
  return $("<a href='" + csv_url + "' />").text("Export as CSV");
};
quasar.action.GoogleNewsArchive = function(intword_names, lang_code, from_date, to_date) {
  var news_search_link = 'http://news.google.com/archivesearch?' + 
    'as_user_ldate=' + quasar.formatDate(from_date) +
    '&as_user_hdate=' + quasar.formatDate(to_date) +
    '&lr=lang_' + lang_code + '&hl=' + lang_code +
    '&q=' + intword_names.join('+');
  return $("<a href='" + news_search_link + "' target='_blank' />").text("Google news search");  
};
quasar.action.GetDataTable = function(gvizPrefix, models) {
  var action = $("<span class='qs-link' />").text("View Data table").click(function (){
    var analysis = new quasar.analysis.DataTable(gvizPrefix);
    var container = $('#analysis_container');  // TODO: the container id shouldn't be hardcoded
    quasar.createAnalysis(container, analysis, models);
  });
  return action;
};
quasar.action.MediaPie = function(models) {
  var action = $("<span class='qs-link' />").text("View Media Pie").click(function (){
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
quasar.analysis.DataTable.prototype.setModels = quasar.setModels;
quasar.analysis.DataTable.prototype.callback = quasar.tableResponse;
quasar.analysis.DataTable.prototype.url = quasar.gvizUrl;
quasar.analysis.DataTable.prototype.visualizationTitle = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.models.entity.to_s() + ' of ' + this.models.word.to_s() + '(' + this.models.word.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.models.date.from_date) + '</b> to <b>' + quasar.formatDate(this.models.date.to_date) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  
  var txt = '';
  if (this.models.source) {
    txt = 'on Source <b>' + this.models.source.to_s() + '</b> limited to kind <b>' + this.models.kind.to_s() + '</b>';
  } else {
    txt = 'Limited to kind <b>' + this.models.kind.to_s() + '</b>';
  }
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;
};
quasar.analysis.DataTable.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/ts','/intword/show'), 'ts'),
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0')];
};

// Analysis : TimeSeries
// ****************

quasar.analysis.TimeSeries = function() {
  this.gvizPrefix = 'gviz/ts';
  this.icon = root_path + 'images/trends.png';
  this.title = 'Trends';
  this.description = 'Analyze time series and study how topics changed over time.';
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
quasar.analysis.TimeSeries.prototype.setModels = quasar.setModels;
quasar.analysis.TimeSeries.prototype.callback = quasar.timelineResponse;
quasar.analysis.TimeSeries.prototype.url = quasar.gvizUrl;
quasar.analysis.TimeSeries.prototype.visualizationTitle = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.models.entity.to_s() + ' of ' + this.models.word.to_s() + '(' + this.models.word.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.models.date.from_date) + '</b> to <b>' + quasar.formatDate(this.models.date.to_date) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'on Source <b>' + this.models.source.to_s() + '</b> limited to kind <b>' + this.models.kind.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;
};
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
  this.icon = root_path + 'images/mediacoverage.png';
  this.title = 'Media Coverage';
  this.description = 'Take a look at how different media and news sources ' +
                     'paid attention to the topics you are interested in. ';  
};
quasar.analysis.StackedChart.prototype.createFields = function() {
  return [
    {name:'word', instance: new quasar.form.Word()},
    {name:'date', instance: new quasar.form.DateRange()},
    {name:'entity', instance: new quasar.form.Entity()},
    {name:'kind', instance: new quasar.form.Kind()}
  ];
};
quasar.analysis.StackedChart.prototype.setModels = quasar.setModels;
quasar.analysis.StackedChart.prototype.callback = quasar.barChartResponse;
quasar.analysis.StackedChart.prototype.url = quasar.gvizUrl;
quasar.analysis.StackedChart.prototype.visualizationTitle = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.models.entity.to_s() + ' of ' + this.models.word.to_s() + '(' + this.models.word.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.models.date.from_date) + '</b> to <b>' + quasar.formatDate(this.models.date.to_date) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'Limited to kind <b>' + this.models.kind.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div; 
};
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
  this.icon = root_path + 'images/popularity.png';
  this.title = 'Popularity';
  this.description = 'See what topics are most popular comparing them against ' +
                     'each other.';  
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
quasar.analysis.PieChart.prototype.setModels = quasar.setModels;
quasar.analysis.PieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.PieChart.prototype.url = quasar.gvizUrl;
quasar.analysis.PieChart.prototype.visualizationTitle = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.models.entity.to_s() + ' of ' + this.models.word.to_s() + '(' + this.models.word.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.models.date.from_date) + '</b> to <b>' + quasar.formatDate(this.models.date.to_date) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'on Source <b>' + this.models.source.to_s() + '</b> limited to kind <b>' + this.models.kind.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;  
};
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
quasar.analysis.MediaPieChart.prototype.setModels = quasar.setModels;
quasar.analysis.MediaPieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.MediaPieChart.prototype.url = quasar.gvizUrl;
quasar.analysis.MediaPieChart.prototype.visualizationTitle = quasar.analysis.StackedChart.prototype.visualizationTitle;
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
  this.icon = root_path + 'images/motion.png';
  this.title = 'News in Motion';
  this.description = 'Watch the evolution of news topics over time and see ' +
                     'how they spread from one media outlet to the other';  
};
quasar.analysis.MotionChart.prototype.createFields = function() {
  return [
    {name: 'word', instance: new quasar.form.Word()},
    {name: 'date', instance: new quasar.form.DateRange()},
    {name: 'entity', instance: new quasar.form.Entity()},
    {name: 'kind', instance: new quasar.form.Kind()}
  ];
};
quasar.analysis.MotionChart.prototype.setModels = quasar.setModels;
quasar.analysis.MotionChart.prototype.callback = quasar.motionChartResponse;
quasar.analysis.MotionChart.prototype.url = quasar.gvizUrl;
quasar.analysis.MotionChart.prototype.visualizationTitle = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.models.entity.to_s() + ' of ' + this.models.word.to_s() + '(' + this.models.word.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.models.date.from_date) + '</b> to <b>' + quasar.formatDate(this.models.date.to_date) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'Limited to kind <b>' + this.models.kind.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;  
};
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
  $("<p>Choose a graph type:</p>").appendTo(formDiv);
   var formControlsDiv = $("<div class='qs-form-controls' >Select one of the above icons</div>");
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
    formControlsDiv.append('<p><b>' + analysis.title + '</b> parameters:</p>');
    var fields = analysis.createFields();
    quasar.createFormFields(formControlsDiv, fields);

    var submit_btn = $("<button id='qs-analysis-btn' />").text('Analyse!');
    submit_btn.appendTo(formControlsDiv);
    submit_btn.click(function() {
      var models = {};
      $.each(fields, function(i, field) { 
        models[field.name] = field.instance.toModel();
      });
      quasar.createAnalysis(analysis_container, analysis, models);
    });
    
    var direct_csv_link = $("<a class='qs-link-csv' href='#'>or export directly to CSV</a>");
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
  analysis.setModels(models);
  var csvUrl = analysis.url() + '&tqx=out:csv%3BreqId:0';
  document.location.href = csvUrl;  // dirty hack to trigger the CSV download
};

quasar.createAnalysis = function(container, analysis, models) {
  analysis.models = models;
  var query = new google.visualization.Query(analysis.url());
  query.setTimeout(15);  
  
  var analysis_div = $("<div class='qs-analysis' style='display:none'/>");
  quasar.icon('close').attr('style', 'float:right').appendTo(analysis_div).click(function() {
    analysis_div.remove();
  });
  analysis.visualizationTitle().appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis-graph'></div>").appendTo(analysis_div);
  $("<img src='" + root_path + "images/spin.gif' alt='Loading...' />").appendTo(graph_div);
  
  var actions_div = $("<div class='qs-analysis-action'></div>").appendTo(analysis_div);
  $('<h3>Actions</h3>').appendTo(actions_div);  
  var actions_list = $("<ul />").appendTo(actions_div);
  
  $.each(analysis.actions(), function(i, action) {
    $("<li />").append(action).appendTo(actions_list);
  });
    
  $("<br clear='both' />").appendTo(analysis_div);
  container.append(analysis_div);
  analysis_div.fadeIn('fast');

  query.send(analysis.callback(graph_div));
};

