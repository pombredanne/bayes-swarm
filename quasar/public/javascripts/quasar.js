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
    chart.draw(data, {width: 300, height: 300, is3D: true, pieJoinAngle: 5, legendFontSize: 10 });
  };
}

quasar.motionChartResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.MotionChart(container.get(0));
    chart.draw(data, {width: 600, height: 400});
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

quasar.form.Word = function() {
  this.language = 'English';
  this.lang_code = 'en';
};
quasar.form.Word.prototype.render = function(formDiv) {
  var that = this;
  $("<span>Language:</span>").appendTo(formDiv);  
  this.it_input = $("<input type='radio' name='language' value='it'>");
  $("<label />").append(this.it_input).append("&nbsp;Italian").appendTo(formDiv);
  this.it_input.click(function (){
    that.language = 'Italian';
    that.lang_code = 'it';    
    that.buildAc('it', ac_label);
  })

  this.en_input = $("<input type='radio' name='language' value='en' checked>");
  $("<label />").append(this.en_input).append("&nbsp;English").appendTo(formDiv);  
  this.en_input.click(function (){
    that.language = 'English';
    that.lang_code = 'en';        
    that.buildAc('en', ac_label);    
  })  
  $('<br />').appendTo(formDiv);
  var ac_label = $("<span>Word:</span>").appendTo(formDiv);
  this.buildAc('en', ac_label);
};
quasar.form.Word.prototype.buildAc = function(lang, placeHolder) {
  var old_ac = this.intword_ac;
  if (old_ac) {
    old_ac.remove();
  }
  that = this;
  this.intword_ac = $("<input name='q' type='text' style='width: 300px' />").insertAfter(placeHolder);
  this.intword_ac.data('suggestions', {});
  this.intword_ac.autocomplete({
    serviceUrl: root_path + "intword/ac",   // TODO: remove absolute url
    minChars: 2,
    width: 300,
    params: {lang: lang},
    delimiter: /,\s*/,
    onSelect: function(value, data) {
      that.intword_ac.data('suggestions')[value] = data;
    }
  });
};
quasar.form.Word.prototype.populate = function() {
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
  return 'id=' + this.intword_ids.join('-') + '&language=' + this.lang_code ;
};
quasar.form.Word.prototype.to_s = function() {
  return this.intword_names.join(',');
};

quasar.form.Source = function() {};
quasar.form.Source.prototype.render = function(formDiv) {
  $("<span>Source:</span>").appendTo(formDiv);
  source_select = $('<select />').appendTo(formDiv);
  $.each(sources, function(i, source) {   // global variable hack
    $("<option value='" + source.id + "'>" + source.name + "</option>").appendTo(source_select);
  });
  this.source_select = source_select;
};
quasar.form.Source.prototype.populate = function() {};
quasar.form.Source.prototype.params = function() {
  return 'source=' + this.source_select.val();
};
quasar.form.Source.prototype.to_s = function() {
  return this.source_select.find(':selected').text();
};

quasar.form.DateRange = function() {};
quasar.form.DateRange.prototype.render = function(formDiv) {
  $("<span>From:</span>").appendTo(formDiv);
  this.from_date_dp = $("<input type='text' />").appendTo(formDiv).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });
  $("<span>&nbsp;&nbsp;</span>").appendTo(formDiv);
  $("<span>To:</span>").appendTo(formDiv);
  this.to_date_dp = $("<input type='text' />").appendTo(formDiv).datepicker(
    { dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });  
};
quasar.form.DateRange.prototype.populate = function() {};
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

quasar.form.Entity = function() {};
quasar.form.Entity.prototype.render = function(formDiv) {
  $("<span>Found in:</span>").appendTo(formDiv);
  this.entity_select = $('<select />').appendTo(formDiv);
  $("<option value='count'>Overall count</option>").appendTo(this.entity_select);
  $("<option value='headingcount'>Headings</option>").appendTo(this.entity_select);
  $("<option value='anchorcount'>Anchors</option>").appendTo(this.entity_select);
  $("<option value='titlecount'>Titles</option>").appendTo(this.entity_select);  
  $("<option value='bodycount'>Body occurrences</option>").appendTo(this.entity_select);
  $("<option value='keywordcount'>Keywords</option>").appendTo(this.entity_select);
};
quasar.form.Entity.prototype.populate = function() {};
quasar.form.Entity.prototype.params = function() {
  return 'entity=' + this.entity_select.val();
};
quasar.form.Entity.prototype.to_s = function() {
  return this.entity_select.find(':selected').text();
};

quasar.form.Kind = function() {};
quasar.form.Kind.prototype.render = function(formDiv) {
  $("<span>Kind:</span>").appendTo(formDiv);
  this.rss_input = $("<input type='radio' name='kind' value='rss'>");
  $("<label />").append(this.rss_input).append("&nbsp;RSS Feed").appendTo(formDiv);
  this.url_input = $("<input type='radio' name='kind' value='url'>");
  $("<label />").append(this.url_input).append("&nbsp;Webpage").appendTo(formDiv);
  this.both_input = $("<input type='radio' name='kind' value='both' checked>");
  $("<label />").append(this.both_input).append("&nbsp;Both").appendTo(formDiv);  
};
quasar.form.Kind.prototype.populate = function() {};
quasar.form.Kind.prototype.params = function() {
  if (this.rss_input.is(':checked')) {
    return 'kind=rss';
  } else if (this.url_input.is(':checked')) {
    return 'kind=url';
  } else {
    return 'kind=both';
  }
};
quasar.form.Kind.prototype.to_s = function() {
  if (this.rss_input.is(':checked')) {
    return 'Rss Feed';
  } else if (this.url_input.is(':checked')) {
    return 'Webpage';
  } else {
    return 'both Rss Feeds and Webpages';
  }  
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

// quasar.action.Permalink = function(permalink_url, type) {
//   return $("<a href='" + permalink_url + '&type=' + type + "' />").text("Permalink");
// };

// Analysis
// ****************

quasar.analysis.TimeSeries = function() {
  this.wordfield = new quasar.form.Word();
  this.datefield = new quasar.form.DateRange();
  this.entityfield = new quasar.form.Entity();
  this.sourcefield = new quasar.form.Source();
  this.kindfield = new quasar.form.Kind();    
  this.fields = [this.wordfield, this.datefield, this.entityfield, this.sourcefield,
                 this.kindfield];
};
quasar.analysis.TimeSeries.prototype.renderForm = function(formDiv) {
  $.each(this.fields, function(i, field) {
    var fieldDiv = $('<div class="qs-form-control" />').appendTo(formDiv);
    field.render(fieldDiv);
  });
};
quasar.analysis.TimeSeries.prototype.populate = function() {
  $.each(this.fields, function(i, field) { field.populate(); });
};
quasar.analysis.TimeSeries.prototype.callback = quasar.timelineResponse;
quasar.analysis.TimeSeries.prototype.url = function() {
  return root_path + 'gviz/ts?' + this.wordfield.params() + 
      '&' + this.entityfield.params() + 
      '&' + this.datefield.params() +
      '&' + this.sourcefield.params() +
      '&' + this.kindfield.params();
};
quasar.analysis.TimeSeries.prototype.title = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.entityfield.to_s() + ' of ' + this.wordfield.to_s() + '(' + this.wordfield.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.datefield.from_date()) + '</b> to <b>' + quasar.formatDate(this.datefield.to_date()) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'on Source <b>' + this.sourcefield.to_s() + '</b> limited to kind <b>' + this.kindfield.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;
};
quasar.analysis.TimeSeries.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/ts','/intword/show'), 'ts'),
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.wordfield.intword_names, 
                                           this.wordfield.lang_code,             
                                           this.datefield.from_date(),
                                           this.datefield.to_date()) ];
};

quasar.analysis.PieChart = function() {
  this.wordfield = new quasar.form.Word();
  this.datefield = new quasar.form.DateRange();
  this.entityfield = new quasar.form.Entity();
  this.sourcefield = new quasar.form.Source();
  this.kindfield = new quasar.form.Kind();    
  this.fields = [this.wordfield, this.datefield, this.entityfield, this.sourcefield,
                 this.kindfield];
};
quasar.analysis.PieChart.prototype.renderForm = function(formDiv) {
  $.each(this.fields, function(i, field) {
    var fieldDiv = $('<div class="qs-form-control" />').appendTo(formDiv);
    field.render(fieldDiv);
  });
};
quasar.analysis.PieChart.prototype.populate = function() {
  $.each(this.fields, function(i, field) { field.populate(); });
};
quasar.analysis.PieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.PieChart.prototype.url = function() {
  return root_path + 'gviz/wordpie?' + this.wordfield.params() + 
      '&' + this.entityfield.params() + 
      '&' + this.datefield.params() +
      '&' + this.sourcefield.params() +
      '&' + this.kindfield.params();
};
quasar.analysis.PieChart.prototype.title = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.entityfield.to_s() + ' of ' + this.wordfield.to_s() + '(' + this.wordfield.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.datefield.from_date()) + '</b> to <b>' + quasar.formatDate(this.datefield.to_date()) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'on Source <b>' + this.sourcefield.to_s() + '</b> limited to kind <b>' + this.kindfield.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;  
};
quasar.analysis.PieChart.prototype.actions = function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/wordpie','/intword/show'), 'wordpie'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.wordfield.intword_names,
                                           this.wordfield.lang_code,
                                           this.datefield.from_date(),
                                           this.datefield.to_date()) ];
};

quasar.analysis.MediaPieChart = function() {
  this.wordfield = new quasar.form.Word();
  this.datefield = new quasar.form.DateRange();
  this.entityfield = new quasar.form.Entity();
  this.sourcefield = new quasar.form.Source();
  this.kindfield = new quasar.form.Kind();    
  this.fields = [this.wordfield, this.datefield, this.entityfield, this.sourcefield,
                 this.kindfield];  
};
quasar.analysis.MediaPieChart.prototype.renderForm = quasar.analysis.PieChart.prototype.renderForm;
quasar.analysis.MediaPieChart.prototype.populate = quasar.analysis.PieChart.prototype.populate;
quasar.analysis.MediaPieChart.prototype.callback = quasar.pieChartResponse;
quasar.analysis.MediaPieChart.prototype.url = function() {
  return root_path + 'gviz/pagepie?' + this.wordfield.params() + 
      '&' + this.entityfield.params() + 
      '&' + this.datefield.params() +
      '&' + this.sourcefield.params() +
      '&' + this.kindfield.params();
};
quasar.analysis.MediaPieChart.prototype.title = quasar.analysis.PieChart.prototype.title;
quasar.analysis.MediaPieChart.prototype.actions =  function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/pagepie','/intword/show'), 'pagepie'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.wordfield.intword_names, 
                                           this.wordfield.lang_code,             
                                           this.datefield.from_date(),
                                           this.datefield.to_date()) ];
};

quasar.analysis.MotionChart = function() {
  this.wordfield = new quasar.form.Word();
  this.datefield = new quasar.form.DateRange();
  this.entityfield = new quasar.form.Entity();
  this.kindfield = new quasar.form.Kind();    
  this.fields = [this.wordfield, this.datefield, this.entityfield,
                 this.kindfield];  
};
quasar.analysis.MotionChart.prototype.renderForm = function(formDiv) {
  $.each(this.fields, function(i, field) {
    var fieldDiv = $('<div class="qs-form-control" />').appendTo(formDiv);
    field.render(fieldDiv);
  });
};
quasar.analysis.MotionChart.prototype.populate = function() {
  $.each(this.fields, function(i, field) { field.populate(); });
};
quasar.analysis.MotionChart.prototype.callback = quasar.motionChartResponse;
quasar.analysis.MotionChart.prototype.url = function() {
  return root_path + 'gviz/motion?' + this.wordfield.params() + 
      '&' + this.entityfield.params() + 
      '&' + this.datefield.params() +
      '&' + this.kindfield.params();
};
quasar.analysis.MotionChart.prototype.title = function() {
  var title_div = $('<div />');
  $('<h2 />').text(this.entityfield.to_s() + ' of ' + this.wordfield.to_s() + '(' + this.wordfield.language + ')').appendTo(title_div);
  var txt = 'From <b>' + quasar.formatDate(this.datefield.from_date()) + '</b> to <b>' + quasar.formatDate(this.datefield.to_date()) + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);

  var txt = 'Limited to kind <b>' + this.kindfield.to_s() + '</b>';
  $('<div class="qs-legend" />').html(txt).appendTo(title_div);
  return title_div;  
};
quasar.analysis.MotionChart.prototype.actions =  function() {
  return [ //quasar.action.Permalink(this.url().replace('/gviz/motion','/intword/show'), 'motion'), 
           quasar.action.CsvLink(this.url() + '&tqx=out:csv%3BreqId:0'),
           quasar.action.GoogleNewsArchive(this.wordfield.intword_names, 
                                           this.wordfield.lang_code,             
                                           this.datefield.from_date(),
                                           this.datefield.to_date()) ];
};


// Global functions (again?)
// ****************

quasar.createChartForm = function(formDiv, subFormDiv, analysis_container, analysis, title, image) {
  var chart = $("<div class='qs-chart' />").appendTo(formDiv);
  chart.append($("<img src='" + image + "'>"));
  chart.click(function() {
    $('.qs-chart').removeClass('qs-chart-selected');
    $(this).addClass('qs-chart-selected');
    subFormDiv.fadeOut('fast').empty();
    subFormDiv.append('<p><b>' + title + '</b> parameters:</p>');
    analysis.renderForm(subFormDiv); 

    var submit_btn = $("<button id='qs-analysis-btn' />").text('Analyse!');
    submit_btn.appendTo(subFormDiv);
    submit_btn.click(function() {
      quasar.createAnalysis(analysis_container, analysis);
    });    
    subFormDiv.fadeIn('fast');
  });
  chart.hover(function() {
    $('#qs-chart-description').append(title);
  }, function() {
    $('#qs-chart-description').empty();
  });
  
}

quasar.createAnalysisForm = function(form_container, analysis_container) {
  var formDiv = $("<div class='qs-form' style='display:none'></div>");
  $("<p>Choose a graph type: <span id='qs-chart-description'></span></p>").appendTo(formDiv);
   var subFormDiv = $("<div class='qs-form-controls' />");
  quasar.createChartForm(formDiv, subFormDiv, analysis_container, new quasar.analysis.TimeSeries(), 'Time Series', root_path + 'images/timeline_chart.png');
  quasar.createChartForm(formDiv, subFormDiv, analysis_container, new quasar.analysis.PieChart(), 'Pie Chart', root_path + 'images/pie_chart.png');
  quasar.createChartForm(formDiv, subFormDiv, analysis_container, new quasar.analysis.MediaPieChart(), 'Media Pie Chart', root_path + 'images/media_chart.png');
  quasar.createChartForm(formDiv, subFormDiv, analysis_container, new quasar.analysis.MotionChart(), 'Motion Chart', root_path + 'images/motion_chart.png');      
  
  $("<br clear='both' />").appendTo(formDiv);
  subFormDiv.appendTo(formDiv);
  form_container.empty().append(formDiv);
  formDiv.fadeIn('fast');
};

quasar.createAnalysis = function(container, analysis) { 
  analysis.populate();
  var query = new google.visualization.Query(analysis.url());
  query.setTimeout(15);  
  
  var analysis_div = $("<div class='qs-analysis' style='display:none'/>");
  quasar.icon('close').attr('style', 'float:right').appendTo(analysis_div).click(function() {
    analysis_div.remove();
  });
  analysis.title().appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis-graph'></div>").appendTo(analysis_div);
  $("<img src='" + root_path + "images/spin.gif' alt='Loading...' />").appendTo(graph_div);
  
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
      $("<img src='" + root_path + "images/spin.gif' alt='Loading...' />").appendTo(table_div);
      query.send(quasar.tableResponse(table_div, this));
    }
  });
  $("<li />").append(action).appendTo(actions_list);
    
  $("<br clear='both' />").appendTo(analysis_div);
  container.append(analysis_div);
  analysis_div.fadeIn('fast');

  query.send(analysis.callback(graph_div));
};

