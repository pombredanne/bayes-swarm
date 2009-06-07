# Helper class that simplifies the work of producing a Rails controller
# capable of exposing Google Visualization APIs datasources, as defined here:
# http://code.google.com/intl/it/apis/visualization/documentation/dev/implementing_data_source.html.
#
# This class requires +gviz.rb+ model class to work.
# A controller that wants to expose a GViz datasource should extend this class
# and interact with the +@gviz+ instance within a +gvizifier+ block as shown
# in the following example:
#
#   class MyGvizController < GvizBaseController
#     def mymethod
#       gvizifier do
#         data = [[ Date.today, 'hello', 10 ],
#                 [ Date.today - 1, 'world', 20 ]]
#         @gviz.add_col('date', :id => 'A' , :label => 'Date').
#               add_col('string', :id => 'B' , :label => 'Name').
#               add_col('number', :id => 'C', :label => 'Count')
#               set_data(data)
#     end
#   end
#
# The +gvizifier+ block takes care of all the boilerplate request handling:
#   * It creates the Gviz model and checks whether it's valid or not.
#     ( it skips block execution for invalid parameters and returns the
#       appropriate error message to the user )
#   * It invokes the correct renderer depending on the requested GViz output
#     format.
#
# The class also provides some helper method to manipulate datasources, such
# as composing and merging them.
# 
# It expects a +debughtml+ erb template to be available. Such template should
# take care of rendering a Gviz model object into an HTML table. It is used
# whenever the user requests an html output.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.
#
class GvizBaseController < ApplicationController
  
  protected
  
  # Helper method to handle all the boilerplate for GViz processing.
  # It expects a block that will receive an initialized and validated GViz model,
  # that can be used to fill the data to be exported.
  #
  # See the class docs for further info.
  def gvizifier
    @gviz = Gviz.from_params(params)
    if @gviz.valid?
      begin
        yield @gviz
      rescue ActiveRecord::RecordNotFound => e
        @gviz.add_error(:id, e.message)
      rescue ArgumentError => e
        @gviz.add_error(:id, e.message)        
      rescue RightAws::AwsError => e
        @gviz.add_error(:id, e.message)
      end
    end
    
    case @gviz[:out]
    when 'json'
      render :json => @gviz.response
    when 'csv'
      send_data(@gviz.response,
        :type => 'text/csv; charset=utf-8; header=present',
        :filename => @csv_filename || csv_filename )
    else
      # html or invalid output format
      render :action => 'debughtml'
    end    
  end
  
  # Utility method to explicitly define the name of the CSV file to be sent to
  # the user when he requests such format. 
  # The name is composed as an underscore-separated list of tokens, the first
  # one being the controller's +action+ that is handling the request and all
  # the remaining ones composed from the method arguments.
  def csv_filename(*tokens)
    @csv_filename = ([] << params[:action] << tokens).flatten.compact.join('_') + '.csv'
  end
  
  # An utility method to compose multiple datasources into a single one.
  # It iterates over all the items of all the datasources and yields to a block
  # that receives the following parameters:
  #   * +heap+ : a map that will accumulate the output datasource. The map key
  #     will become the first column in the output datasource. The map values
  #     should be arrays representing the remainder of each row.
  #   * +dataitem+: a row from a datasource.
  #   * +i+: an index referring to the datasource +dataitem+ belongs to.
  #
  # It's basically a reduce operator.
  # +datasources+ should be an enumeration. Each datasource should be an
  # enumeration as well that iterates over the rows that compose it.
  # The resulting datasource is sorted by key (i.e. the first column), and
  # optionally reversed depending on the +reverse+ parameters.
  def compose(datasources, reverse=false)
    heap = {}
    datasources.each_with_index do |datasource, i| 
      datasource.each do |dataitem|
        yield heap, dataitem, i
      end
    end
    res = heap.sort
    res.map! { |keyvalues| keyvalues.flatten }
    res.reverse! if reverse
    res
  end    
  
  # Sums multiple datasources into a single one. Each datasource should have
  # 2 columns: the first one being the row key, the second one being the
  # value to be summed.
  def sum(datasources, reverse=false)
    compose(datasources, reverse) do |heap, dataitem, i|
      heap[dataitem[0]] = (heap[dataitem[0]] || 0) + dataitem[1]
    end
  end
  
  # Merges multiple datasources vertically into a single one.
  # Each datasource should have 2 columns: the first one being the row key, 
  # the second one being the associated value. Given +n+ inputs, the output 
  # datasource will have n+1 columns. Column ordering of values preserves the
  # ordering in the input datasources. Empty cells will have a zero filled in.
  def merge(datasources, reverse=false)
    compose(datasources, reverse) do |heap, dataitem, i|
      heap[dataitem[0]] ||= Array.new(datasources.size).fill(0)
      heap[dataitem[0]][i] += dataitem[1]      
    end
  end
  
end