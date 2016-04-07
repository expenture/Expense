json.key_format!(camelize: :lower) if camelize_keys

if @error
  json.status 'error'
  json.error @error
else
  json.status 'confirmation_pending'
  json.user @user, partial: '_models/user', as: :user
end
