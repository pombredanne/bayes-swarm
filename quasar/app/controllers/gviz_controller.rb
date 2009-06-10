class GvizController < GvizBaseController
  
  def ts
    sdb = Sdb.new
    gvizifier do |gviz|
      pages = params[:source] && params[:source] != '0' ? Source.find(params[:source]).pages.map { |p| p.id } : nil
      
      kind = Kind.find_by_kind(params[:kind])
      if kind
        kind = kind.kind
      end

      csv_filename(params[:id], pages ? pages.join('-') : nil, params[:entity], params[:from_date], params[:to_date])
      gviz.add_col('date', :id => 'scantime' , :label => 'Date')
      series = []
    
      iws = Intword.find(params[:id].split('-'))
      # TODO: should not allow more than x intwords.
      iws.each do |iw|
        series << iw.time_series(sdb,  params[:from_date], params[:to_date], kind, params[:entity], pages)
        gviz.add_col('number', :id => iw.id, :label => iw.name)
      end
      gviz.set_data(merge(series))
    end
  end
  
  def motion
    sdb = Sdb.new
    gvizifier do |gviz|
      kind = Kind.find_by_kind(params[:kind])
      if kind
        kind = kind.kind
      end

      csv_filename(params[:id], params[:entity], params[:from_date], params[:to_date])
      
      gviz.add_col('string', :id => 'name', :label => 'Word')
      gviz.add_col('date', :id => 'scantime' , :label => 'Date')
      # Add the columns for each source iterating by sorted key (source name), to preserve column alignment.      
      Source.find(:all).map { |source| source.name }.sort.each_with_index do |sourcename, i|
        gviz.add_col('number', :id => "count#{i}", :label => "#{sourcename}")
      end
      # TODO: should not allow more than x intwords.
      iws = Intword.find(params[:id].split('-'))
      # Always pass nil as the pages to select. Even though Aggregate.motion understands the parameter, at
      # this moment do not allow multiple selection of sources, so it's all or nothing.
      gviz.set_data(Aggregate.motion(sdb, params[:from_date], params[:to_date], iws, kind, params[:entity], nil))
    end
  end
    
  def wordpie
    pie(:intword)
  end
  
  def pagepie
    pie(:page)
  end
  
  protected
  def pie(by)
    sdb = Sdb.new
    gvizifier do |gviz|
      pages = params[:source] && params[:source] != '0' ? Source.find(params[:source]).pages.map { |p| p.id } : nil      
      
      kind = Kind.find_by_kind(params[:kind])
      if kind
        kind = kind.kind
      end
      
      csv_filename(params[:id], pages ? pages.join('-') : params[:entity], params[:from_date], params[:to_date])
      gviz.add_col('string', :id => 'name', :label => 'name')
      gviz.add_col('number', :id => params[:entity], :label => params[:entity])
      iws = Intword.find(params[:id].split('-'))
      gviz.set_data(Aggregate.pie(sdb, by, params[:from_date], params[:to_date], iws, kind, params[:entity], pages))
    end
  end
  
  
end