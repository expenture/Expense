json.email @user.email

if time_format == 'integer'
  json.created_at @user.created_at_as_i
  json.updated_at @user.updated_at_as_i
else
  json.created_at @user.created_at
  json.updated_at @user.updated_at
end
