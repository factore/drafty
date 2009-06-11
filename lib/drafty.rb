# Drafty
module FactorE #nodoc
  module Drafty
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def is_drafty(options = {})
        cattr_accessor :draft_class_name
        self.draft_class_name = options[:class_name] || "#{self.to_s}Draft"
        
        has_many :drafts, :class_name => self.draft_class_name, :foreign_key => 'draft_parent_id'
        
        extend FactorE::Drafty::SingletonMethods
        include FactorE::Drafty::InstanceMethods
        # Setup The Draft Class  
        Object.const_set(draft_class_name, Class.new(ActiveRecord::Base))
        draft_class.set_table_name(options[:table_name]) unless options[:table_name].blank?      
        draft_class.default_scope(:order => "updated_at DESC")
      end
    end
    
    module SingletonMethods
      def draft_class
        const_get(draft_class_name)
      end
      
      # Finds the original as well as its most recent draft.  If the most recent draft is more recent than the original
      # it updates the original's attributes (not saving them of course) and returns it.  Otherwise it returns the original, unhindered.
      # This means you're never directly working with a draft object, only an original object with the attributes of the draft.
      def draft_find(id)
        original, draft = self.find(id), draft_class.first(:conditions => { :draft_parent_id => id }, :order => "updated_at DESC", :limit => 1)
    	  items = [original]
    	  items << draft unless draft.nil?
    	  original.attributes = items.sort_by { |i| i.updated_at }.reverse[0].attributes.reject { |k,v| k == "draft_parent_id" }
    	  return original
    	end
    	
    	def create_draft(params, parent_id)
    	  draft = draft_class.new(params)
    	  draft.draft_parent_id = parent_id
    	  return true if draft.save
    	end
    end
    
    module InstanceMethods
      def revert
        page = Page.find(self.id)
        page.updated_at = Time.now
        page.save
      end
      
      def load_draft(id)
        draft = self.drafts.find_by_id(id)
        self.attributes = draft.attributes.reject { |k,v| k == "draft_parent_id" }
      end
      
    end
    
    
  end
end