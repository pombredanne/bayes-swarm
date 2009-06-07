class GvizController < GvizBaseController
  
  def ts
    sdb = Sdb.new
    gvizifier do |gviz|
      # TODO: pages parameter is not compatible with iw.time_series signature
      csv_filename(params[:id], params[:pages], params[:entity], params[:interval])
      pages = params[:pages] ? params[:pages].split(',') : nil        
      gviz.add_col('date', :id => 'scantime' , :label => 'Date')
      series = []
    
      iws = Intword.find(params[:id].split('-'))
      # TODO: should not allow more than x intwords.
      iws.each do |iw|
        series << iw.time_series(sdb, params[:interval], params[:entity], pages)
        gviz.add_col('number', :id => iw.id, :label => iw.name)
      end
      gviz.set_data(merge(series))
    end
  end
    
  def pie
    sdb = Sdb.new
    gvizifier do |gviz|
      csv_filename(params[:id], params[:entity], params[:interval])
      gviz.add_col('string', :id => 'name', :label => 'name')
      gviz.add_col('number', :id => params[:entity], :label => params[:entity])
      iws = Intword.find(params[:id].split('-'))
      gviz.set_data(Aggregate.pie(sdb, iws, params[:entity], params[:interval]))
    end
  end
  
end