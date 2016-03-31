# This class is used for handling request errors, it can be initialized with an
# `Exception`, or by manually giving the error status, code and message
class Error < HashWithIndifferentAccess
  def initialize(obj)
    self.status = 500
    self.code = 'internal_server_error'
    obj = obj.errors if obj.is_a? ActiveRecord::Base

    if obj.is_a? Hash
      obj.each_pair do |k, v|
        self[k] = v
      end
    elsif obj.is_a? ActiveRecord::RecordNotFound
      self.status = 404
      self.code = 'not_found'
      self.message = obj.message
    elsif obj.is_a? ActiveModel::Errors
      self.status = 400
      self.code = 'bad_attributes'
      self.message = "#{obj.instance_variable_get(:@base).class.name}: #{obj.full_messages.join(', ')}"
      self.model = obj.instance_variable_get(:@base).class.name
    elsif obj.is_a? ActionController::ParameterMissing
      self.status = 400
      self.code = 'parameter_missing'
      self.message = obj.message
    end
  end

  def status
    self[:status]
  end

  def status=(status)
    self[:status] = status.to_i
  end

  def code
    self[:code]
  end

  def code=(code)
    self[:code] = code.to_s
  end

  def model
    self[:model]
  end

  def model=(model)
    self[:model] = model.to_s
  end

  def message
    self[:message]
  end

  def message=(message)
    self[:message] = message.to_s
  end
end
