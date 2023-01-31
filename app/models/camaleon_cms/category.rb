module CamaleonCms
  class Category < CamaleonCms::TermTaxonomy
    alias_attribute :site_id, :term_group
    alias_attribute :post_type_id, :status

    scope :no_empty, -> { where('count > 0') } # return all categories that contains at least one post
    scope :empty, -> { where(count: [0, nil]) } # return all categories that does not contain any post

    has_many :posts, foreign_key: :objectid, through: :term_relationships, source: :object
    has_many :children, class_name: 'CamaleonCms::Category', foreign_key: :parent_id, dependent: :destroy
    belongs_to :parent, class_name: 'CamaleonCms::Category', foreign_key: :parent_id, required: false
    belongs_to :post_type, class_name: 'CamaleonCms::PostType', foreign_key: :parent_id, inverse_of: :categories, required: false
    belongs_to :site, required: false

    has_many :values, as: :record, class_name: 'FieldValue', dependent: :destroy
    delegate :field_groups, :fields, to: :post_type, prefix: :category

    before_save :set_site
    before_destroy :set_posts_in_default_category


    # return the post type of this category
    def post_type
      parent ? path.first.post_type : super
    end

    def path
      cama_fetch_cache('path') do
        (parent&.path || []) + [self]
      end
    end

    private

    def set_site
      self.site_id ||= post_type.site_id
      self.status ||= post_type.id
    end

    # rescue all posts to assign into default category if they don't have any category assigned
    def set_posts_in_default_category
      category_default = post_type.default_category
      return if category_default == self

      posts.each do |post|
        if post.categories.where.not(id: id).blank?
          post.assign_category(category_default.id)
        end
      end
    end
  end
end
