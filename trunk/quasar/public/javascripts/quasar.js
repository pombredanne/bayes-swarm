// TODO: absolute paths are used here, and will fail if we deploy in a subdomain
// namespace
quasar = {}

quasar.createAnalysisForm = function(form_container, analysis_container) {
  var formDiv = $("<div class='qs-form' style='display:none'></div>");

  $("<label>Word:</label>").appendTo(formDiv);
  var intword_ac = $("<input name='q' type='text' style='width: 300px' />").appendTo(formDiv);
  intword_ac.data('suggestions', {});
  intword_ac.autocomplete({
    serviceUrl: "/intword/ac",
    minChars: 2,
    width: 300,
    params: { lang: 'it'},
    delimiter: /,\s*/,
    onSelect: function(value, data) {
      intword_ac.data('suggestions')[value] = data;
    }
  });
  $("<span>&nbsp;&nbsp;</span>").appendTo(formDiv);
    
  $("<label>Type:</label>").appendTo(formDiv);
  var type_select = $('<select />').appendTo(formDiv)
  $("<option value='ts'>Time Series</option>").appendTo(type_select);
  $("<option value='pie'>Pie Chart</option>").appendTo(type_select);  
  $("<br />").appendTo(formDiv);
  $("<label>From:</label>").appendTo(formDiv);
  var from_date = $("<input type='text' />").appendTo(formDiv).datepicker({ dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });
  $("<span>&nbsp;&nbsp;</span>").appendTo(formDiv);
  $("<label>To:</label>").appendTo(formDiv);
  var to_date = $("<input type='text' />").appendTo(formDiv).datepicker({ dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true });
  $("<br />").appendTo(formDiv);
  
  var submit_btn = $("<input type='submit' value='Analyze' id='qs-analysis-btn' />");
  submit_btn.appendTo(formDiv);
  submit_btn.click(function() {
    quasar.createAnalysis(analysis_container, intword_ac, type_select, from_date, to_date);
  });
  
  form_container.empty().append(formDiv);
  formDiv.fadeIn('fast');
};

quasar.icon = function(iconname) {
  return $('<div />').addClass('ui-state-default ui-corner-all qs-icon-box').
    append($("<span />").addClass('ui-icon ui-icon-' + iconname + ' qs-icon')).
    hover(
  		function() { $(this).addClass('ui-state-hover'); }, 
  		function() { $(this).removeClass('ui-state-hover'); }
  	);;
}

quasar.createAnalysis = function(container, intword_ac, select, from_date, to_date) {
  var suggestions = intword_ac.data('suggestions');
  var intword_names = $.map(intword_ac.val().split(','), function(name) { return $.trim(name); });
  var intword_ids = [];
  $.each(intword_names, function(i, name) {
    if (suggestions[name]) {
      intword_ids.push(suggestions[name]);
    }    
  });
  var type = $(select).val();
  var today = new Date();
  var one_month_ago = new Date();
  one_month_ago.setMonth(one_month_ago.getMonth()-1);
  var from_date = from_date.datepicker('getDate') || one_month_ago;
  var to_date = to_date.datepicker('getDate') || today;
  
  var query = new google.visualization.Query('/gviz/' + type + '/' + intword_ids.join('-') + '?entity=count&from_date=' + quasar.formatDate(from_date) + '&to_date=' + quasar.formatDate(to_date));
  query.setTimeout(15);  
  
  var analysis_div = $("<div class='qs-analysis' style='display:none'/>");
  quasar.icon('close').attr('style', 'float:right').appendTo(analysis_div).click(function() {
    analysis_div.remove();
  });
  $('<h2 />').text('Word:' + intword_names.join(',')).appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis-graph'></div>").appendTo(analysis_div);
  $("<img src='/images/spin.gif' alt='Loading...' />").appendTo(graph_div);
  
  var actions_div = $("<div class='qs-analysis-action'></div>").appendTo(analysis_div);
  $('<h3>Actions</h3>').appendTo(actions_div);  
  var actions_list = $("<ul />").appendTo(actions_div);

  var csv_link = '/gviz/' + type + '/' + intword_ids.join('-') + '?entity=count&from_date=' + quasar.formatDate(from_date) + '&to_date=' + quasar.formatDate(to_date) + '&tqx=out:csv%3BreqId:0';
  var action = $("<a href='" + csv_link + "' />").text("Export as CSV");
  $("<li />").append(action).appendTo(actions_list);
  
  // TODO: remove this language once the language selector goes in.
  language = 'it';
  var news_search_link = 'http://news.google.com/archivesearch?' + 
    'as_user_ldate=' + quasar.formatDate(from_date) +
    '&as_user_hdate=' + quasar.formatDate(to_date) +
    '&lr=lang_' + language + '&hl=' + language +
    '&q=' + intword_names.join('+');
  var action = $("<a href='" + news_search_link + "' target='_blank' />").text("Google news search");
  $("<li />").append(action).appendTo(actions_list);
  
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

  if (type == 'ts') {
    query.send(quasar.timelineResponse(graph_div));
  } else if (type == 'pie') {
    query.send(quasar.pieChartResponse(graph_div));
  }
  intword_ac.val('').data('suggestions', {}).focus();
}

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