// TODO: absolute paths are used here, and will fail if we deploy in a subdomain
// namespace
quasar = {}

quasar.createAnalysisForm = function(form_container, analysis_container) {
  var formDiv = new Element('DIV', {'class' : 'qs-form'});
  
  var type_label = new Element('LABEL').update('Type: ');
  var type_select = new Element('SELECT');
  var type_option_ts = new Element('OPTION', {value: 'ts'}).update('Time Series');
  var type_option_pie = new Element('OPTION', {value: 'pie'}).update('Pie Chart');
  type_select.appendChild(type_option_ts);
  type_select.appendChild(type_option_pie);  
  
  var intword_label = new Element('LABEL').update('Word: ');
  var intword_input = new Element('INPUT');
  var submit_btn = new Element('INPUT', {type: 'submit', value: 'Please Wait...', id:'qs-analysis-btn', disabled: 'true'});
  submit_btn.observe('click', function(event) {
    quasar.createAnalysis(event, analysis_container, 
      type_select.options[type_select.selectedIndex].value, 
      intword_input);
  });
  formDiv.appendChild(intword_label);
  formDiv.appendChild(intword_input);
  formDiv.appendChild(new Element('SPAN').update('&nbsp;&nbsp;'));
  formDiv.appendChild(type_label);
  formDiv.appendChild(type_select);
  formDiv.appendChild(new Element('BR'));
  formDiv.appendChild(submit_btn);
  form_container.appendChild(formDiv);
};

quasar.enableAnalysisForm = function() {
  $('qs-analysis-btn').removeAttribute('disabled');
  $('qs-analysis-btn').setAttribute('value', 'Analyze');
};

quasar.createAnalysis = function(event, container, type, intword_input) {
  var intword_id = intword_input.value;
  var analysis_div = new Element('DIV');
  var title = new Element('H2').update('Word: ' + intword_id)
  var graph_div = new Element('DIV', {'class': 'qs-analysis'});
  var loading_img = new Element('IMG', {src: '/images/spin.gif', alt: 'Loading...'});
  var actions_div = new Element('DIV', {'class': 'qs-analysis-action'});
  actions_div.appendChild(new Element('H3').update('Actions'));
  var actions_list = new Element('UL');
  var action = new Element('A', {href: '#'}).update('Remove');
  action.observe('click', function(event) {
    container.removeChild(analysis_div);
  });
  var action_item = new Element('LI');
  action_item.appendChild(action);
  actions_list.appendChild(action_item);
  
  var action = new Element('A', {href: '/gviz/' + type + '/' + intword_id + '?entity=count&interval=6m&tqx=out:csv%3BreqId:0'}).update('Export as CSV');
  var action_item = new Element('LI');
  action_item.appendChild(action);
  actions_list.appendChild(action_item);

  
  actions_div.appendChild(actions_list);  
  analysis_div.appendChild(title);
  analysis_div.appendChild(graph_div);
  analysis_div.appendChild(actions_div);
  analysis_div.appendChild(new Element('BR', {clear: 'both'}));
  graph_div.appendChild(loading_img);
  container.appendChild(analysis_div);  
  var query = new google.visualization.Query('/gviz/' + type + '/' + intword_id + '?entity=count&interval=6m')
  query.setTimeout(15);
  if (type == 'ts') {
    query.send(quasar.timelineResponse(graph_div));
  } else if (type == 'pie') {
    query.send(quasar.pieChartResponse(graph_div));
  }
  intword_input.value = '';
  intword_input.focus();
}

quasar.timelineResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();
    var chart = new google.visualization.AnnotatedTimeLine(container);
    chart.draw(data);
  };
};

quasar.pieChartResponse = function(container) {
  return function(response) {
    if (!quasar.initResponseArea(response, container)) {
      return;
    }

    var data = response.getDataTable();    
    var chart = new google.visualization.PieChart(container);
    chart.draw(data, {width: 250, height: 200, is3D: true });
  };
}

quasar.initResponseArea = function (response, container) {
  var elem = container;
  while (elem.firstChild) { elem.removeChild(elem.firstChild); }
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
      elem.innerHTML = '<span class="qs-description">This visualization is taking a long time, please wait...</span>';
    } else {
     elem.innerHTML = '<span class="qs-description">Error in query: ' + response.getMessage() + '</span>';
    }
  }
  return !response.isError();
};