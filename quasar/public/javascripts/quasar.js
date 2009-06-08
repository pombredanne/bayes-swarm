// TODO: absolute paths are used here, and will fail if we deploy in a subdomain
// namespace
quasar = {}

quasar.createAnalysisForm = function(form_container, analysis_container) {
  var formDiv = $("<div class='qs-form' style='display:none'></div>");

  $("<label>Word:</label>").appendTo(formDiv);
  var intword_input = $("<input type='text' />").appendTo(formDiv);
  $("<span>&nbsp;&nbsp;</span>").appendTo(formDiv);
    
  $("<label>Type:</label>").appendTo(formDiv);
  var type_select = $('<select />').appendTo(formDiv)
  $("<option value='ts'>Time Series</option>").appendTo(type_select);
  $("<option value='pie'>Pie Chart</option>").appendTo(type_select);  
  $("<br />").appendTo(formDiv);
  
  var submit_btn = $("<input type='submit' value='Analyze' id='qs-analysis-btn' />");
  submit_btn.appendTo(formDiv);
  submit_btn.click(function() {
    quasar.createAnalysis(analysis_container, intword_input, type_select);
  });
  
  form_container.empty().append(formDiv);
  formDiv.fadeIn('fast');
};

quasar.createAnalysis = function(container, intword, select) {
  var intword_id = $(intword).val();
  var type = $(select).val()
  
  var analysis_div = $("<div style='display:none'/>");
  $('<h2 />').text('Word:' + intword_id).appendTo(analysis_div);
  var graph_div = $("<div class='qs-analysis'></div>").appendTo(analysis_div);
  $("<img src='/images/spin.gif' alt='Loading...' />").appendTo(graph_div);
  
  var actions_div = $("<div class='qs-analysis-action'></div>").appendTo(analysis_div);
  $('<h3>Actions</h3>').appendTo(actions_div);  
  var actions_list = $("<ul />").appendTo(actions_div);
  
  var action = $("<a href='#' />").text('Remove').click(function() {
    analysis_div.remove();
  })
  $("<li />").append(action).appendTo(actions_list);

  var csv_link = '/gviz/' + type + '/' + intword_id + '?entity=count&interval=6m&tqx=out:csv%3BreqId:0';
  var action = $("<a href='" + csv_link + "' />").text("Export as CSV");
  $("<li />").append(action).appendTo(actions_list);
  
  $("<br clear='both' />").appendTo(analysis_div);
  container.append(analysis_div);
  analysis_div.fadeIn('fast');
  
  var query = new google.visualization.Query('/gviz/' + type + '/' + intword_id + '?entity=count&interval=6m')
  query.setTimeout(15);
  if (type == 'ts') {
    query.send(quasar.timelineResponse(graph_div));
  } else if (type == 'pie') {
    query.send(quasar.pieChartResponse(graph_div));
  }
  intword.val('').focus();
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