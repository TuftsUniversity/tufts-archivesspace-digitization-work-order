require 'csv'
require_relative 'id_generators/generator_interface'

class DOReport

  attr_reader :items

  BASE_COLUMNS = [
    {:header => "Resource ID",           :proc => Proc.new {|resource, item| resource_id(resource)}},
    {:header => "Ref ID",                :proc => Proc.new {|resource, item| ref_id(item)}},
    {:header => "URI",                   :proc => Proc.new {|resource, item| record_uri(item)}},
	{:header => "Item ID",               :proc => Proc.new {|resource, item| item_id(item)}},
    {:header => "Container Indicator 1", :proc => Proc.new {|resource, item, dates, box| indicator_1(box)}},
    {:header => "Container Indicator 2", :proc => Proc.new {|resource, item, dates, box| indicator_2(box)}},
    {:header => "Container Indicator 3", :proc => Proc.new {|resource, item, dates, box| indicator_3(box)}},
    {:header => "Title",                 :proc => Proc.new {|resource, item| record_title(item)}},
    {:header => "Component ID",          :proc => Proc.new {|resource, item| component_id(item)}},
	{:header => "Creators",       		 :proc => Proc.new {|resource, item, dates, box, series, subseries, creators| print_creators(creators)}},
	{:header => "Subjects",				 :proc => Proc.new {|resource, item, dates, box, series, subseries, creators, subjects| print_subjects(subjects)}},
	{:header => "Rights Notes",			 :proc => Proc.new {|resource, item, dates, box, series, subseries, creators, subjects, restriction_notes| print_restriction_notes(restriction_notes)}},
	
	
  ]
  

  SERIES_COLUMNS = [
    {:header => "Series",                :proc => Proc.new { |resource, item, dates, box, series| record_title(series) }}
  ]

  SUBSERIES_COLUMNS = [
    {:header => "Sub-Series",            :proc => Proc.new { |resource, item, dates, box, series, subseries| record_title(subseries) }}
  ]

  BARCODE_COLUMNS = [
    {:header => "Barcode",               :proc => Proc.new {|resource, item, dates, box| barcode(box)}}
  ]

  DATES_COLUMNS = [
    {:header => "Dates",                 :proc => Proc.new {|resource, item, dates| date_string(dates)}}
  ]

  # CREATORS_COLUMNS = [
	# {:header => "Creators 2",          	 :proc => Proc.new {|resource, item, dates, box, series, subseries, creators| print_creators(creators)}}
  # ]

  def initialize(uris, opts = {})
    @uris = uris
    @generate_ids = opts[:generate_ids]

    if @generate_ids
      Dir.glob(base_dir("id_generators/*.rb")).each do |file|
        require(File.absolute_path(file))
      end

      generator_class = 'DefaultGenerator'
      if AppConfig.has_key?(:digitization_work_order_id_generator) 
        generator_class = AppConfig[:digitization_work_order_id_generator]
      end

      @id_generator = Kernel.const_get(generator_class).new
    end

    @columns = BASE_COLUMNS
    @extras = allowed_extras.select { |e| opts.fetch(:extras) { [] }.include?(e) }
    @extras.each do |extra|
      @columns += self.class.const_get(extra.upcase + '_COLUMNS')
    end

    build_items
  end


  def to_stream
    StringIO.new(@tsv)
  end


  private


  def base_dir(path = nil)
    base = File.absolute_path(File.dirname(__FILE__))
    if path
      File.join(base, path)
    else
      base
    end
  end


  def build_items
    ids = []
    @uris.each do |uri|
      parsed = JSONModel.parse_reference(uri)

      # only archival_objects
      next unless parsed[:type] == "archival_object"

      ids << parsed[:id]
    end

    ds = ArchivalObject
           .select_all(:archival_object)
           .join_table(:left, :archival_object___c, :parent_id => :id)
           .where(Sequel.qualify(:archival_object, :id) => ids, Sequel.qualify(:c, :id) => nil)

    resource = nil
    containers = nil
    dates = get_dates(ids) if @extras.include?('dates')
	creators = get_creators(ids)
	subjects = get_subjects(ids)
	restriction_notes = get_restriction_notes(ids)

#	creators = "Creators Test" if @extras.include?('creators')
    @tsv = generate_line(@columns.map {|col| col[:header]})

    ds.each do |ao|
      if @generate_ids && !ao[:component_id]
        ao = generate_id(ao)
      end

      item = {'item' => ao}

      unless resource
        resource = Resource[ao.root_record_id]
        containers = resource.quick_containers
      end

      item['resource'] = resource

      (series, subseries, all) = find_ancestors(ao)
      item['series'] = series
      item['subseries'] = subseries

      all.each do |ancestor|
        item['box'] = containers[ancestor.id]
        break if item['box']
      end

      item['dates'] = dates[ao.id] if @extras.include?('dates')
	  item['creators'] = creators[ao.id]
	  item['subjects'] = subjects[ao.id]
	  item['restriction_notes'] = restriction_notes[ao.id]
#	  item['creators'] = creators if @extras.include?('creators')
      add_row_to_report(item)
    end
  end


  def generate_id(ao)
    ao[:component_id] = @id_generator.generate(ao)
    ao.save(:columns => [:component_id, :system_mtime])
    ao
  end


  def get_dates(ids)
    dates = {}
    DB.open do |db|
      db[:date]
        .join(:enumeration_value___label, :id => :label_id)
        .where(:archival_object_id => ids)
        .select(Sequel.as(:date__archival_object_id, :archival_object_id),
                Sequel.as(:label__value, :label),
                Sequel.as(:date__begin, :begin),
                Sequel.as(:date__end, :end),
                Sequel.as(:date__expression, :expression))
        .each do |date|
        dates[date[:archival_object_id]] ||= []
        dates[date[:archival_object_id]] << date
      end
    end
    dates
  end
  
  def get_creators(ids)
	creators = {}

	DB.open do |db|
     db[:linked_agents_rlshp]
		  .left_outer_join(:agent_person, :agent_person__id => :linked_agents_rlshp__agent_person_id)
		  .left_outer_join(:agent_corporate_entity, :agent_corporate_entity__id => :linked_agents_rlshp__agent_corporate_entity_id)
		  .left_outer_join(:agent_family, :agent_family__id => :linked_agents_rlshp__agent_family_id)
		  .left_outer_join(:agent_software, :agent_software__id => :linked_agents_rlshp__agent_software_id)
		  .left_outer_join(:name_person, :name_person__agent_person_id => :agent_person__id)
		  .left_outer_join(:name_corporate_entity, :name_corporate_entity__agent_corporate_entity_id => :agent_corporate_entity__id)
		  .left_outer_join(:name_family, :name_family__agent_family_id => :agent_family__id)
		  .left_outer_join(:name_software, :name_software__agent_software_id => :agent_software__id)
		  .where(:archival_object_id => ids)
		  .select(Sequel.as(:linked_agents_rlshp__archival_object_id, :archival_object_id),	
				  Sequel.as(:linked_agents_rlshp__role_id, :role_id),
				  Sequel.as(:name_person__sort_name, :person),
				  Sequel.as(:name_corporate_entity__sort_name, :corporate_entity),
				  Sequel.as(:name_family__sort_name, :family),
				  Sequel.as(:name_software__sort_name, :software))
		  .each do |creator|


				creators[creator[:archival_object_id]] ||= []
				creators[creator[:archival_object_id]] << creator
				

		  end
	end
	creators
  end
    
  def get_subjects(ids)
  
	subjects = {}
	
	DB.open do |db|
		db[:subject_rlshp]
			.join(:subject, :subject__id => :subject_rlshp__subject_id)
			.where(:archival_object_id => ids)
			.select(Sequel.as(:subject__title, :title),
				  Sequel.as(:subject_rlshp__subject_id, :subject_id),
				  Sequel.as(:subject_rlshp__archival_object_id, :archival_object_id))
			.each do |subject|
			
				subjects[subject[:archival_object_id]] ||= []
				subjects[subject[:archival_object_id]] << subject
			end
		
	end
	subjects
  end
  
  def get_restriction_notes(ids)
	restriction_notes = {}
	DB.open do |db|
	  db[:rights_restriction]
		.join(:note, :note__archival_object_id => :rights_restriction__archival_object_id)
		.where(:rights_restriction__archival_object_id => ids)
		.select(Sequel.as(:rights_restriction__archival_object_id, :archival_object_id),
				Sequel.as(:rights_restriction__restriction_note_type, :restriction_note_type),
				Sequel.as(:note__notes, :notes))
		.each do |restriction_note|
			restriction_notes[restriction_note[:archival_object_id]] ||= []
			restriction_notes[restriction_note[:archival_object_id]] << restriction_note
		
		end
	end
	restriction_notes
  end
  
  def find_ancestors(ao)
    @visited_aos ||= {}
    subseries = nil
    series = nil
    all = [ao]

    while true
      if ao[:parent_id].nil?
        break
      end

      @visited_aos[ao.parent_id] ||= ArchivalObject[ao[:parent_id]]
      ao = @visited_aos[ao.parent_id]

      all << ao
      if ao.level == 'subseries'
        subseries = ao
      end
      if ao.level == 'series'
        series = ao
        break
      end
    end

    return series, subseries, all
  end


  def generate_line(data)
    CSV.generate_line(data, :col_sep => "\t")
  end


  def allowed_extras
    ['series', 'subseries', 'barcode', 'dates']
  end


  def empty_row
    {
      'resource' => {},
      'item' => {},
      'dates' => [],
      'box' => {},
      'series' => {},
      'subseries' => {},
	  'creators' => {},
	  'subjects' => {},
	  'restriction_notes' => {},
    }
  end


  def add_row_to_report(row)
    mrow = empty_row.merge(row)
    @tsv += generate_line(@columns.map {|col| col[:proc].call(mrow['resource'],
                                                              mrow['item'],
                                                              mrow['dates'],
                                                              mrow['box'],
                                                              mrow['series'],
                                                              mrow['subseries'],
															  mrow['creators'],
															  mrow['subjects'],
															  mrow['restriction_notes'])})
  end


  # Cell value generators
  def self.record_uri(record)
    record.uri
  end


  def self.record_title(record)
    return '' unless record
    record.title
  end


  def self.resource_id(resource)
    JSON.parse(resource.identifier).compact.join('.')
  end


  def self.ref_id(item)
    item.ref_id
  end


  def self.box_concat(box, &block)
    return '' unless box
    out = box.map { |b| block.call(b) }
    out.compact.join(', ')
  end


  def self.indicator_1(box)
    box_concat(box) { |b| b[:top_container][:indicator] if b[:top_container] }
  end


  def self.barcode(box)
    box_concat(box) { |b| b[:top_container][:barcode] if b[:top_container] }
  end


  def self.indicator_2(box)
    box_concat(box) { |b| b[:sub_container][:indicator_2] }
  end


  def self.indicator_3(box)
    box_concat(box) { |b| b[:sub_container][:indicator_3] }
  end

  def self.item_id(item)
	item[:id]
  end
  def self.component_id(item)
    item[:component_id]
  end

  def self.print_creators(creators)


	return_array = Array.new
	

	unless creators.nil?
		
		creators.each do |subarray|
			
			if subarray[:role_id] == 878
		
				unless subarray[:person].nil?
					return_array << subarray[:person]
				end 
				
				unless subarray[:corporate_entity].nil?
					return_array << subarray[:corporate_entity]
				end 
				
				unless subarray[:family].nil?
					return_array << subarray[:family]
				end
				
				unless subarray[:software].nil?
					return_array << subarray[:software]
				end
			end
		end
	
	end
	
	return_string = return_array.join("; ")
	return return_string

	
  end
  
  def self.print_subjects(subjects)
  
	return_array = Array.new
	
	unless subjects.nil?
		
		subjects.each do |subject|
		
			unless subject[:title].nil?
				return_array << subject[:title]
			end 
		
		
		end
	
	end
	return_string = return_array.join("; ")
	return return_string
  end
  
  def self.print_restriction_notes(restriction_notes)
	return_array = Array.new
	
	unless restriction_notes.nil?
		
		restriction_notes.each do |restriction_note|
		
			# unless restriction_note[:restriction_note_type].nil?
				# return_array << "#{restriction_note[:restriction_note_type]}: "
			# end
		
			unless restriction_note[:notes].nil?
				notes = eval(restriction_note[:notes])
				
				#return_array << notes
				
				if notes[:type] == "accessrestrict" or notes[:type] == "userestrict"
				

					return_array << "#{notes[:type]}: "
					
					subnotes = notes[:subnotes]
					

					
					
					subnotes.each do |subnote|
						unless subnote[:content].nil?
							content = subnote[:content]
							return_array << "#{content}"
						
						end
						
					
					end
				end


			end
		end
	end
	return_string = return_array.join("; ")
	return_string = return_string.gsub(": ;",":")
	return return_string
  end
  
  def self.print_creators_item(item)
  
	return 'blank creators item' unless item[:creators]
	

	item[:creators]
  end
  
  
  
  def self.creators(item)
  
	item[:created_by]
	
	
  end
  
  def self.date_string(dates)
    return '' unless dates
    dates.map { |date|
      dates = [date[:begin], date[:end]].compact.join('--')
      "#{date[:label]}: #{dates}"
    }.join('; ')
  end

end
