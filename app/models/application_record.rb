class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def replace_attributes(new_attributes, except: [:id, :uid, :user_id, :created_at, :updated_at])
    except.map!(&:to_s)

    attributes.each do |attribute_name, _value|
      next if except.include? attribute_name
      self[attribute_name] = new_attributes[attribute_name]
    end

    self
  end

  def created_at_as_i
    created_at && created_at.to_i * 1000
  end

  def updated_at_as_i
    updated_at && updated_at.to_i * 1000
  end
end
