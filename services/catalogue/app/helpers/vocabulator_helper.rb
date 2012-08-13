module VocabulatorHelper

  def vocabulary(feature_fields, dataset_uuid)
    results = {}
    
    dataset_terms = execute(["SELECT feature_field_position, term_id, term_source FROM feature_vocabulary WHERE dataset_uuid = ?", dataset_uuid])

    dataset_terms.each do |term|
      result = execute("SELECT * FROM vocabulator_#{term['term_source']} WHERE id = #{term['term_id']}")[0]
      if result.key?('abbreviation')
        result['description'] = result['abbreviation']
      end
      
      field_name = feature_fields[term['feature_field_position'].to_i]

      if !results[field_name]
        results[field_name] = {}
      end
      if !results[field_name][term['term_source']]
        results[field_name][term['term_source']] = []
      end

      results[field_name][term['term_source']].push({ 'id' => result['id'], 'name' => result['name'], 'description' => result['description'] })
    end

    results
  end
  

  def vocabulary_summary(dataset_uuid)
    results = []
    
    dataset_terms = execute(["SELECT term_id, term_source FROM feature_vocabulary WHERE dataset_uuid = ?", dataset_uuid])

    all_terms = []    
    if Rails.cache.exist?("vocabulary_all_terms_group_by")
      all_terms = Rails.cache.fetch("vocabulary_all_terms_group_by")
    else
      all_terms = execute("SELECT term_id, term_source, COUNT(*) FROM feature_vocabulary GROUP BY term_id, term_source ORDER BY COUNT(*) DESC").to_a
      Rails.cache.write("vocabulary_all_terms_group_by", all_terms) unless !all_terms
    end

    dataset_terms_with_count = []
    dataset_terms.each do |d_term|
      dataset_terms_with_count.push(all_terms.find { |s_term| (d_term['term_id'] == s_term['term_id'] && d_term['term_source'] == s_term['term_source']) })
    end    
    dataset_terms_with_count.compact!
    dataset_terms_with_count.uniq!
    
    dataset_terms_with_count.each do |term|
      result = execute("SELECT * FROM vocabulator_#{term['term_source']} WHERE id = #{term['term_id']}")[0]
      if result.key?('abbreviation')
        result['description'] = result['abbreviation']
      end
      result.merge!({'count' => term['count']})

      results.push(result)
    end
    
    results
  end 
  
  def save_feature_vocabulary(feature_vocabulary, dataset_uuid)
    FeatureVocabulary.create(feature_vocabulary.each { |v| v.merge!({ :dataset_uuid => dataset_uuid}) })
    Rails.cache.delete("vocabulary_all_terms_group_by")
  end
  
  def save_vocabulary_unit_terms(properties, dataset_uuid)
    unit_terms = VocabulatorUnits.find(:all)
    
    shared_unit_terms = []
    properties.each_with_index do |term, i|
      working_terms = unit_terms.find_all { |unit| term.strip.match(/#{unit['name'].strip}/) || term.strip.match(/\(#{unit['abbreviation'].strip}\)| #{unit['abbreviation'].strip} |_#{unit['abbreviation'].strip}/) }
      working_terms.map! { |t| t.serializable_hash.merge!({ 'feature_field_position' => i }) }
      
      shared_unit_terms.push(working_terms)
    end
    shared_unit_terms.flatten!
    shared_unit_terms.compact!
    
    shared_unit_terms_for_feature_vocabulary = []
    shared_unit_terms.each do |term|
      shared_unit_terms_for_feature_vocabulary.push({ 'term_id' => term['id'], 'term_source' => 'units', :feature_field_position => term['feature_field_position'] })
    end
  
    save_feature_vocabulary(shared_unit_terms_for_feature_vocabulary, dataset_uuid)
  end
  
  def vocabulary_keywords(dataset_uuid)
    keywords = []
    
    terms = vocabulary_summary(dataset_uuid)
    terms.each do |term|
      keywords.push(term['name']) if term['name'] && !term['name'].empty?
    end unless terms.empty?
    
    keywords
  end

end