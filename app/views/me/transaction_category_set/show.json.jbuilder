json.key_format!(camelize: :lower) if camelize_keys

json.transaction_category_set @transaction_category_set

if @error
  json.error @error
end
