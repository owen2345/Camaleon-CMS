module CamaleonCms::CustomFieldsRead extend ActiveSupport::Concern
  included do
    before_destroy :_destroy_custom_field_groups
    # DEPRECATED, INSTEAD USE: custom_fields
    has_many :fields, ->(object){ where(:object_class => object.class.to_s.gsub("Decorator","").gsub("CamaleonCms::",""))} , :class_name => "CamaleonCms::CustomField" ,foreign_key: :objectid
    # DEPRECATED, INSTEAD USE: custom_field_values
    has_many :field_values, ->(object){where(object_class: object.class.to_s.gsub("Decorator","").gsub("CamaleonCms::",""))}, :class_name => "CamaleonCms::CustomFieldsRelationship", foreign_key: :objectid, dependent: :delete_all
    # DEPRECATED, INSTEAD USE: custom_field_groups
    has_many :field_groups, ->(object){where(object_class: object.class.to_s.parseCamaClass)}, :class_name => "CamaleonCms::CustomFieldGroup", foreign_key: :objectid
  end

  # get custom field groups for current object
  # only: Post_type, Post, Category, PostTag, Widget, Site and a Custom model pre configured
  # Sample: mypost.get_field_groups() ==> return fields for posts from parent posttype
  # Sample: mycat.get_field_groups() ==> return fields for categories from parent posttype
  # Sample: myposttag.get_field_groups() ==> return fields for posttags from parent posttype
  # @return collections CustomFieldGroup
  def get_field_groups(_args = {})
    class_name = self.class.to_s.parseCamaClass
    case class_name
      when 'Category','PostTag'
        self.post_type.get_field_groups(kind: class_name)
      when 'NavMenuItem'
        self.main_menu.custom_field_groups
      else # 'Plugin' or other classes
        self.field_groups
    end
  end

  # get custom field value
  # _key: custom field key
  # if value is not present, then return default
  # return default only if the field was not registered
  def get_field_value(_key, _default = nil, group_number = 0)
    v = get_field_values(_key, group_number).first rescue _default
    v.present? ? v : _default
  end
  alias_method :get_field, :get_field_value
  alias_method :get_field!, :get_field_value

  # get custom field values
  # _key: custom field key
  def get_field_values(_key, group_number = 0)
    custom_field_values.loaded? ? custom_field_values.select{|f| f.custom_field_slug == _key && f.group_number == group_number}.map{|f| f.value } : custom_field_values.where(custom_field_slug: _key, group_number: group_number).pluck(:value)
  end
  alias_method :get_fields, :get_field_values

  # return the values of custom fields grouped by group_number
  # field_keys: (array of keys)
  # samples: my_object.get_fields_grouped(['my_slug1', 'my_slug2'])
  #   return: [
  #             { 'my_slug1' => ["val 1"], 'my_slug2' => ['val 2']},
  #             { 'my_slug1' => ["val2 for slug1"], 'my_slug2' => ['val 2 for slug2']}
  #   ] ==> 2 groups
  #
  #   return: [
  #             { 'my_slug1' => ["val 1", 'val 2 for fields multiple support'], 'my_slug2' => ['val 2']},
  #             { 'my_slug1' => ["val2 for slug1", 'val 2'], 'my_slug2' => ['val 2 for slug2']}
  #             { 'my_slug1' => ["val3 for slug1", 'val 3'], 'my_slug2' => ['val 3 for slug2']}
  #   ] ==> 3 groups
  #
  #   puts res[0]['my_slug1'].first ==> "val 1"
  def get_fields_grouped(field_keys)
    res = []
    custom_field_values.where(custom_field_slug: field_keys).order(group_number: :asc).group_by(&:group_number).each do |group_number, group_fields|
      group = {}
      field_keys.each do |field_key|
        _tmp = []
        group_fields.each{ |field| _tmp << field.value if field_key == field.custom_field_slug }
        group[field_key] = _tmp if _tmp.present?
      end
      res << group
    end
    res
  end

  # return all values
  # {key1: "single value", key2: [multiple, values], key3: value4} if include_options = false
  # {key1: {values: "single value", options: {a:1, b: 4}}, key2: {values: [multiple, values], options: {a=1, b=2} }} if include_options = true
  def get_field_values_hash(include_options = false)
    fields = {}
    self.custom_field_values.to_a.uniq.each do |field_value|
      custom_field = field_value.custom_fields
      values = custom_field.values.where(objectid: self.id).pluck(:value)
      fields[field_value.custom_field_slug] = custom_field.cama_options[:multiple].to_s.to_bool ? values : values.first unless include_options
      fields[field_value.custom_field_slug] = {values: custom_field.cama_options[:multiple].to_s.to_bool ? values : values.first, options: custom_field.cama_options, id: custom_field.id} if include_options
    end
    fields.to_sym
  end

  # return all custom fields for current element
  # {my_field_slug: {options: {}, values: [], name: '', ...} }
  # deprecated f attribute
  def get_fields_object(f=true)
    fields = {}
    self.custom_field_values.eager_load(:custom_fields).to_a.uniq.each do |field_value|
      custom_field = field_value.custom_fields
      # if custom_field.options[:show_frontend].to_s.to_bool
      values = custom_field.values.where(objectid: self.id).pluck(:value)
      fields[field_value.custom_field_slug] = custom_field.attributes.merge(options: custom_field.cama_options, values: custom_field.cama_options[:multiple].to_s.to_bool ? values : values.first)
      # end
    end
    fields.to_sym
  end


  # add a custom field group for current model
  # @param data (Hash)
    # name: name for the group
    # slug: key for group (if slug = _default => this will never show title and description)
    # description: description for the group (optional)
    # is_repeat: (boolean, optional -> default false) indicate if group support multiple format (repeated values)
  def add_custom_field_group(data)
    get_field_groups.create!(data.merge(record: self))
  end
  alias_method :add_field_group, :add_custom_field_group

  def default_custom_field_group
    get_field_groups.where(slug: '_default').first ||
      add_custom_field_group(name: "Default Field Group", slug: "_default")
  end

  # Add custom fields for a default group:
  # This will create a new group with slug=_default if it doesn't exist yet
  # more details in add_manual_field(item, options) from custom field groups
  def add_field(data, settings)
    default_custom_field_group.add_manual_field(data, settings)
  end
  alias_method :add_custom_field_to_default_group, :add_field

  # return field object for current model
  def get_field_object(slug)
    CamaleonCms::CustomField.where(
      slug: slug,
      parent_id: get_field_groups.pluck(:id),
    ).first
  end

  # save all fields sent from browser (reservated for browser request)
  # sample:
  # {
  #   "0"=>{ "untitled-text-box"=>{"id"=>"262", "values"=>{"0"=>"33333"}}},
  #   "1"=>{ "untitled-text-box"=>{"id"=>"262", "values"=>{"0"=>"33333"}}}
  # }
  def set_field_values(datas = {})
    if datas.present?
      ActiveRecord::Base.transaction do 
        self.custom_field_values.delete_all
        datas.each do |index, fields_data|
          fields_data.each do |field_key, values|
            if values[:values].present?
              order_value = -1
              ((values[:values].is_a?(Hash) || values[:values].is_a?(ActionController::Parameters)) ? values[:values].values : values[:values]).each do |value|
                item = self.custom_field_values.create!({custom_field_id: values[:id], custom_field_slug: field_key, value: fix_meta_value(value), term_order: order_value += 1, group_number: values[:group_number] || 0})
              end
            end
          end
        end
      end
    end
  end

  # update new value for field with slug _key
  # Sample: my_posy.update_field_value('sub_title', 'Test Sub Title')
  def update_field_value(_key, value = nil, group_number = 0)
    self.custom_field_values.where(custom_field_slug: _key, group_number: group_number).first.update_column('value', value) rescue nil
  end

  # Set custom field values for current model
  # key: slug of the custom field
  # value: array of values for multiple values support
  # value: string value
  def save_field_value(key, value, order = 0, clear = true)
    set_field_value(key, value, {clear: clear, order: order})
  end

  # Set custom field values for current model (support for multiple group values)
  # key: (string required) slug of the custom field
  # value: (array | string) array: array of values for multiple values support, string: uniq value for the custom field
  # args:
  #   field_id: (integer optional) identifier of the custom field
  #   order: order or position of the field value
  #   group_number: number of the group (only for custom field group with is_repeat enabled)
  #   clear: (boolean, default true) if true, will remove previous values and set these values, if not will append values
  # return false if the was not saved because there is not present the field with slug: key
  # sample: my_post.set_field_value('subtitle', 'Sub Title')
  # sample: my_post.set_field_value('subtitle', ['Sub Title1', 'Sub Title2']) # set values for a field (for fields that support multiple values)
  # sample: my_post.set_field_value('subtitle', 'Sub Title', {group_number: 1})
  # sample: my_post.set_field_value('subtitle', 'Sub Title', {group_number: 1, group_number: 1}) # add field values for fields in group 1
  def set_field_value(key, value, args = {})
    args = {order: 0, group_number: 0, field_id: nil, clear: true}.merge(args)
    args[:field_id] = get_field_object(key).id rescue nil unless args[:field_id].present?
    unless args[:field_id].present?
      raise ArgumentError, "There is no custom field configured for #{key}"
    end
    self.custom_field_values.where({custom_field_slug: key, group_number: args[:group_number]}).delete_all if args[:clear]
    v = {custom_field_id: args[:field_id], custom_field_slug: key, value: fix_meta_value(value), term_order: args[:order], group_number: args[:group_number]}
    if value.is_a?(Array)
      value.each do |val|
        self.custom_field_values.create!(v.merge({value: fix_meta_value(val)}))
      end
    else
      self.custom_field_values.create!(v)
    end
  end

  private
  def fix_meta_value(value)
    if (value.is_a?(Array) || value.is_a?(Hash) || value.is_a?(ActionController::Parameters))
      value = value.to_json
    end
    value
  end

  def _destroy_custom_field_groups
    class_name = self.class.to_s.parseCamaClass
    if ['Category','Post','PostTag'].include?(class_name)
      CamaleonCms::CustomFieldGroup.where(objectid: self.id, object_class: class_name).destroy_all
    elsif ['PostType'].include?(class_name)
      get_field_groups(kind: 'all').destroy_all
    elsif ["NavMenuItem"].include?(class_name) # menu items doesn't include field groups
    else
      get_field_groups().destroy_all if get_field_groups.present?
    end
  end
end
