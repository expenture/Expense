class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def created_at_as_i
    created_at && created_at.to_i * 1000
  end

  def updated_at_as_i
    updated_at && updated_at.to_i * 1000
  end

  def deleted_at_as_i
    deleted_at && deleted_at.to_i * 1000
  end
end
