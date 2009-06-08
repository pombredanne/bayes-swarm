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
  
  var submit_btn = $("<input type='submit' value='Analyze' id='qs-analysis-btn' />");
  submit_btn.appendTo(formDiv);
  submit_btn.click(function() {
    quasar.createAnalysis(analysis_container, intword_ac, type_select);
  });
  
  form_container.empty().append(formDiv);
  formDiv.fadeIn('fast');
};

quasar.createAnalysis = function(container, intword_ac, select) {
  var suggestions = intword_ac.data('suggestions');
  var intword_names = $.map(intword_ac.val().split(','), function(name) { return $.trim(name); });
  var intword_ids = [];
  $.each(intword_names, function(i, name) {
    if (suggestions[name]) {
      intword_ids.push(suggestions[name]);
    }    
  });
  var type = $(select).val()
  
  var analysis_div = $("<div class='qs-analysis' style='display:none'/>");
  $('<h2 />').text('Word:' + intword_names.join(',')).appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis-graph'></div>").appendTo(analysis_div);
  $("<img src='/images/spin.gif' alt='Loading...' />").appendTo(graph_div);
  
  var actions_div = $("<div class='qs-analysis-action'></div>").appendTo(analysis_div);
  $('<h3>Actions</h3>').appendTo(actions_div);  
  var actions_list = $("<ul />").appendTo(actions_div);
  
  var action = $("<a href='#' />").text('Remove this chart').click(function() {
    analysis_div.remove();
  })
  $("<li />").append(action).appendTo(actions_list);

  var csv_link = '/gviz/' + type + '/' + intword_ids.join('-') + '?entity=count&interval=6m&tqx=out:csv%3BreqId:0';
  var action = $("<a href='" + csv_link + "' />").text("Export as CSV");
  $("<li />").append(action).appendTo(actions_list);
  
  high_date = new Date();
  low_date = new Date();
  low_date.setMonth(low_date.getMonth() -6);
  language = 'it';
  var news_search_link = 'http://news.google.com/archivesearch?' + 
    'as_user_ldate=' + low_date.getFullYear() + '/' + (low_date.getMonth() +1) + '/' + low_date.getDate() +
    '&as_user_hdate=' + high_date.getFullYear() + '/' + (high_date.getMonth() +1) + '/' + high_date.getDate() +
    '&lr=lang_' + language + '&hl=' + language +
    '&q=' + intword_names.join('+');
  var action = $("<a href='" + news_search_link + "' target='_blank' />").text("Google news search");
  $("<li />").append(action).appendTo(actions_list);
  
  
  $("<br clear='both' />").appendTo(analysis_div);
  container.append(analysis_div);
  analysis_div.fadeIn('fast');
  
  var query = new google.visualization.Query('/gviz/' + type + '/' + intword_ids.join('-') + '?entity=count&interval=6m')
  query.setTimeout(15);
  if (type == 'ts') {
    query.send(quasar.timelineResponse(graph_div));
  } else if (type == 'pie') {
    query.send(quasar.pieChartResponse(graph_div));
  }
  intword_ac.val('').data('suggestions', {}).focus();
}

quasar.timelineResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();
    var chart = new google.visualization.AnnotatedTimeLine(container.get(0));
    chart.draw(data);
  };
};

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