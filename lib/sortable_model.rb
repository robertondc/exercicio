module SortableModel
    
  extend ActiveSupport::Concern
  
  included do
    default_scope order("position")
    before_create :put_last_position
    #after_destroy :reorder_positions          
  end

  private

  def put_last_position
   self.position = self.class.last_new_position
  end
  
  def reorder_positions
    self.class.reorder(:position)
  end

  module ClassMethods
  
    def update_positions(id,position)
      transaction do
        model = self.find(id)
        model.position = self.last_new_position
        model.save
        if (position.to_i > model.position)
          update_all(
              ['position = position-1 where position <= ?', position]
          )
        else
          update_all(
              ['position = position+1 where position >= ?', position]
          )
        end
        model.position = position
        model.save
      end
      
    end
  
    def reorder(column)
      models = self.unscoped.all(:order => column)
      replace_position_with_index(models)
    end
  
    def last_new_position
      last = self.maximum(:position)
      last.nil? ? 0 : last + 1
    end
    
    private
          
    def replace_position_with_index(models)
      models.each_with_index do |model,index|
        update_model_position(model,index) if model.position != index
      end
    end
    
    def update_model_position(model,new_position)
      model.position = new_position
      model.save
    end
    
  end
    
end
