if @error
  json.status 'error'
  json.error @error
else
  json.(@user, :email, :created_at, :updated_at)
  json.status 'confirmation_pending'
end
