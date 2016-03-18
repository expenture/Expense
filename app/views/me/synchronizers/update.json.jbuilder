json.key_format!(camelize: :lower) if camelize_keys

json.synchronizer @synchronizer, partial: '_models/synchronizer', as: :synchronizer

if @error
  json.error @error
end
