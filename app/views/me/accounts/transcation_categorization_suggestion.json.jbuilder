json.key_format!(camelize: :lower) if camelize_keys

json.category_code @category_code

if @error
  json.error @error
end
