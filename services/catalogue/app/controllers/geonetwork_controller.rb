class GeonetworkController < ApplicationController
  
  respond_to :xml
  
  def metadata    
    @dataset = Dataset.find_by_uuid(params[:id]).first
    
    @related_datasets = []
    
    if @dataset.dataset_groups.count > 0
      @dataset.dataset_groups.first.datasets.each do |d|
        if d.uuid != params[:id]
          @related_datasets.push(d)
        end
      end
    end    
    
    @keywords = @dataset.feature.keywords
  end
  
  def info
    @dataset = Dataset.find_by_uuid(params[:id]).first
  end
  
  def mef_import_list
    uuids = []
    Dataset.all.each do |dataset|
      uuids.push(dataset.uuid)
    end
    
    render :xml => uuids
  end
  
  def group
    @feature_type = FeatureType.find_by_name(params[:id]).first    
  end
  
  def group_import_list
    ids = {}
    FeatureType.all.each do |feature|
      ids.store(feature.name, feature.id.to_s)
    end
    render :xml => ids
  end
end