// TODO: absolute paths are used here, and will fail if we deploy in a subdomain
// namespaces
quasar = {};
quasar.action = {};
quasar.form = {};
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
}

quasar.pieChartResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.PieChart(container.get(0));
    chart.draw(data, {width: 250, height: 200, is3D: true });
  };
}

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

quasar.form.Word = function() {};
quasar.form.Word.prototype.render = function(formDiv) {
  $("<label>Word:</label>").appendTo(formDiv);
  var that = this;
  this.intword_ac = $("<input name='q' type='text' style='width: 300px' />").appendTo(formDiv);
  this.intword_ac.data('suggestions', {});
  this.intword_ac.autocomplete({
    serviceUrl: "/intword/ac",   // TODO: remove absolute url
    minChars: 2,
    width: 300,
    params: { lang: 'it'},
    delimiter: /,\s*/,
    onSelect: function(value, data) {
      that.intword_ac.data('suggestions')[value] = data;
    }
  });  
};
quasar.form.Word.prototype.parse = function() {
  var suggestions = this.intword_ac.data('suggestions');
  this.intword_names = $.map(this.intword_ac.val().split(','), 
                             function(name) { return $.trim(name); });
  var intword_ids = [];
  $.each(this.intword_names, function(i, name) {
    if (suggestions[name]) {
      intword_ids.push(suggestions[name]);
    }    
  });
  this.intword_ids = intword_ids;
};
quasar.form.Word.prototype.params = function() {
  return this.intword_ids.join('-');
};
quasar.form.Word.prototype.to_s = function() {
  return this.intword_names.join(',');
};


quasar.form.DateRange = function() {};
quasar.form.DateRange.prototype.render = function(formDiv) {
  $("<label>From:</label>").appendTo(formDiv);
  this.from_date_dp = $("<input type='text' />").appendTo(formDiv).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });
  $("<span>&nbsp;&nbsp;</span>").appendTo(formDiv);
  $("<label>To:</label>").appendTo(formDiv);
  this.to_date_dp = $("<input type='text' />").appendTo(formDiv).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });  
};
quasar.form.DateRange.prototype.parse = function() {
};
quasar.form.DateRange.prototype.params = function() {
  return 'from_date=' + quasar.formatDate(this.from_date()) + '&to_date=' + quasar.formatDate(this.to_date());
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


// Actions
// ****************

quasar.action.CsvLink = function(csv_url) {
  return $("<a href='" + csv_url + "' />").text("Export as CSV");
};
quasar.action.GoogleNewsArchive = function(intword_names, from_date, to_date) {
  // TODO: remove this language once the language selector goes in.
  language = 'it';
  var news_search_link = 'http://news.google.com/archivesearch?' + 
    'as_user_ldate=' + quasar.formatDate(from_date) +
    '&as_user_hdate=' + quasar.formatDate(to_date) +
    '&lr=lang_' + language + '&hl=' + language +
    '&q=' + intword_names.join('+');
  return $("<a href='" + news_search_link + "' target='_blank' />").text("Google news search");  
};

quasar.action.DataTable = function() {
  
};

// Analysis
// ****************

quasar.analysis.TimeSeries = function() {
  this.wordfield = new quasar.form.Word();
  this.datefield = new quasar.form.DateRange();
  this.fields = [this.wordfield, this.datefield];
};
quasar.analysis.TimeSeries.prototype.renderForm = function(formDiv) {
  $.each(this.fields, function(i, field) {
    var fieldDiv = $('<div />').appendTo(formDiv);
    field.render(fieldDiv);
  });
};
quasar.analysis.TimeSeries.prototype.parse = function() {
  $.each(this.fields, function(i, field) { field.parse(); });
};
quasar.analysis.TimeSeries.prototype.callback = quasar.timelineResponse;
quasar.analysis.TimeSeries.prototype.url = function() {
  return '/gviz/ts/' + this.wordfield.params() + '?entity=count&' + this.datefield.params();
};
quasar.analysis.TimeSeries.prototype.title = function() {
  return 'Word:' + this.wordfield.to_s();
};
quasar.analysis.TimeSeries.prototype.actions = function() {
  return [ quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.wordfield.intword_names, 
                                           this.datefield.from_date(),
                                           this.datefield.to_date()) ];
};

quasar.analysis.PieChart = function() {
  this.wordfield = new quasar.form.Word();
  this.datefield = new quasar.form.DateRange();
  this.fields = [this.wordfield, this.datefield];  
};
quasar.analysis.PieChart.prototype.renderForm = function(formDiv) {
  $.each(this.fields, function(i, field) {
    var fieldDiv = $('<div />').appendTo(formDiv);
    field.render(fieldDiv);
  });
};
quasar.analysis.PieChart.prototype.parse = function() {
  $.each(this.fields, function(i, field) { field.parse(); });
};
quasar.analysis.PieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.PieChart.prototype.url = function() {
  return '/gviz/pie/' + this.wordfield.params() + '?entity=count&' + this.datefield.params();
};
quasar.analysis.PieChart.prototype.title = function() {
  return 'Word:' + this.wordfield.to_s();
};
quasar.analysis.PieChart.prototype.actions = function() {
  return [ quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.wordfield.intword_names, 
                                           this.datefield.from_date(),
                                           this.datefield.to_date()) ];
};

// Global functions (again?)
// ****************

quasar.createAnalysisForm = function(form_container, analysis_container) {
  var formDiv = $("<div class='qs-form' style='display:none'></div>");
  $("<label>Type:</label>").appendTo(formDiv);
  var type_select = $('<select />').appendTo(formDiv)
  $("<option value='ts'>Time Series</option>").appendTo(type_select);
  $("<option value='pie'>Pie Chart</option>").appendTo(type_select);
  var subFormDiv = $("<div />").appendTo(formDiv);
  var analysis = null;  
  type_select.change(function() {
    subFormDiv.empty();
    if ($(this).val() == 'ts') {
      analysis = new quasar.analysis.TimeSeries();
    } else if ($(this).val() == 'pie') {
      analysis = new quasar.analysis.PieChart();
    }    
    analysis.renderForm(subFormDiv);
  });
  $("<br />").appendTo(formDiv);
  
  var submit_btn = $("<input type='submit' value='Analyze' id='qs-analysis-btn' />");
  submit_btn.appendTo(formDiv);
  submit_btn.click(function() {
    quasar.createAnalysis(analysis_container, analysis);
  });
  
  form_container.empty().append(formDiv);
  type_select.val('ts');
  type_select.change();
  formDiv.fadeIn('fast');
};

quasar.createAnalysis = function(container, analysis) { 
  analysis.parse();
  var query = new google.visualization.Query(analysis.url());
  query.setTimeout(15);  
  
  var analysis_div = $("<div class='qs-analysis' style='display:none'/>");
  quasar.icon('close').attr('style', 'float:right').appendTo(analysis_div).click(function() {
    analysis_div.remove();
  });
  $('<h2 />').text(analysis.title()).appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis-graph'></div>").appendTo(analysis_div);
  $("<img src='/images/spin.gif' alt='Loading...' />").appendTo(graph_div);
  
  var actions_div = $("<div class='qs-analysis-action'></div>").appendTo(analysis_div);
  $('<h3>Actions</h3>').appendTo(actions_div);  
  var actions_list = $("<ul />").appendTo(actions_div);
  
  $.each(analysis.actions(), function(i, action) {
    $("<li />").append(action).appendTo(actions_list);
  });

  // Datatable action is separated from the other actions because it affects
  // the layout directly
  var action = $("<span class='qs-link' />").text("View Data table").click(function (){
    if ($(graph_div).children('.qs-datatable').size() == 0) {
      var table_div = $('<div class="qs-datatable"/>').appendTo(graph_div);
      $("<img src='/images/spin.gif' alt='Loading...' />").appendTo(table_div);
      query.send(quasar.tableResponse(table_div, this));
    }
  });
  $("<li />").append(action).appendTo(actions_list);
    
  $("<br clear='both' />").appendTo(analysis_div);
  container.append(analysis_div);
  analysis_div.fadeIn('fast');

  query.send(analysis.callback(graph_div));
};

