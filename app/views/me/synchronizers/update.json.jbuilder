json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.synchronizer @synchronizer, partial: '_models/synchronizer', as: :synchronizer
