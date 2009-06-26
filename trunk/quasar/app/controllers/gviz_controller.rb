class GvizController < GvizBaseController
  
  def ts
    sdb = Sdb.new
    gvizifier do |gviz|
      pages = Page.fill_pages(params)
      iws = Intword.fill_intwords(params)
      kind = Kind.fill_kind(params)
      
      csv_filename(iws.map { |iw| iw.id }.join('-'), 
                   pages ? pages.join('-') : nil, 
                   params[:entity], 
                   params[:from_date], 
                   params[:to_date])

      gviz.add_col('date', :id => 'scantime' , :label => 'Date')
      series = []    
      iws.each do |iw|
        series << iw.time_series(sdb,  params[:from_date], params[:to_date], 
                                 kind, params[:entity], pages)
        gviz.add_col('number', :id => iw.id, :label => iw.name)
      end
      gviz.set_data(merge(series))
    end
  end
  
  def stacked
    sdb = Sdb.new
    gvizifier do |gviz|
      iws = Intword.fill_intwords(params)
      kind = Kind.fill_kind(params)
      
      csv_filename(iws.map { |iw| iw.id }.join('-'), 
                   params[:entity], 
                   params[:from_date], 
                   params[:to_date]) 
                   
      gviz.add_col('string', :id => 'source', :label=> 'Source')
      series = []    
      iws.each do |iw|
        # Always pass nil as the pages to select. 
        # Even though Intword.media_share understands the parameter, 
        # at this moment do not allow multiple selection of sources, so it's all
        # or nothing. 
        series << Aggregate.pie(sdb, :page, params[:from_date], params[:to_date],
                      [iw], kind, params[:entity], nil)
        gviz.add_col('number', :id => iw.id, :label => iw.name)
      end
      gviz.set_data(otherify(merge(series), 10))          
    end
  end  
  
  def motion
    sdb = Sdb.new
    gvizifier do |gviz|
      iws = Intword.fill_intwords(params)
      kind = Kind.fill_kind(params)
      
      csv_filename(iws.map { |iw| iw.id }.join('-'), 
                   params[:entity], 
                   params[:from_date], 
                   params[:to_date])

      gviz.add_col('string', :id => 'name', :label => 'Word')
      gviz.add_col('date', :id => 'scantime' , :label => 'Date')
      # Add the columns for each source iterating by sorted key (source name), 
      # to preserve column alignment.
      Source.find(:all).map { |source| source.name }.sort.each_with_index do |sourcename, i|
        gviz.add_col('number', :id => "count#{i}", :label => "#{sourcename}")
      end
            
      # Always pass nil as the pages to select. 
      # Even though Aggregate.motion understands the parameter, at this moment do
      # not allow multiple selection of sources, so it's all or nothing.
      gviz.set_data(Aggregate.motion(sdb, params[:from_date], params[:to_date], 
                                     iws, kind, params[:entity], nil))
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
      pages = Page.fill_pages(params)
      iws = Intword.fill_intwords(params)
      kind = Kind.fill_kind(params)
      
      csv_filename(iws.map { |iw| iw.id }.join('-'), 
                   pages ? pages.join('-') : nil,
                   params[:entity], 
                   params[:from_date], 
                   params[:to_date])

      gviz.add_col('string', :id => 'name', :label => 'name')
      gviz.add_col('number', :id => params[:entity], :label => params[:entity])
      
      gviz.set_data(Aggregate.pie(sdb, by, params[:from_date], params[:to_date],
                    iws, kind, params[:entity], pages))
    end
  end
end