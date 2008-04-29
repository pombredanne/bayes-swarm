class AdminController < ApplicationController
  #layout "admin"
  layout "standard"
  before_filter :authorize
  
  def index
  end
  
  def translate_new
    #@view_translations = ViewTranslation.find(:all, :conditions => [ 'built_in = 1 AND language_id = ?', Locale.language.id ], :order => 'text')
    # untranslated only
    @view_translations = ViewTranslation.find(:all, :conditions => [ 'text is NULL AND language_id = ?', Locale.language.id ], :order => 'tr_key')
  end

  def translate_old
    @view_translations = ViewTranslation.find(:all, :conditions => [ 'built_in = 1 AND text is NOT NULL AND language_id = ?', Locale.language.id ], :order => 'tr_key')
  end

  def translation_text
    @translation = ViewTranslation.find(params[:id])
    render :text => @translation.text || ""  
  end

  def set_translation_text
    @translation = ViewTranslation.find(params[:id])
    previous = @translation.text
    @translation.text = params[:value]
    @translation.text = previous unless (@translation.text!='' and @translation.save)
    render :text => @translation.text || '[no translation]'
  end   
end
