json.key_format!(camelize: :lower) if camelize_keys

json.synchronizers @synchronizers, partial: '_models/synchronizer', as: :synchronizer
