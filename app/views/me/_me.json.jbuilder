json.errors user.errors if user.errors.present?

# IDs
json.id user.id

# Basic information
json.name user.name
json.email user.email
json.profile_picture_url user.profile_picture_url
json.cover_photo_url user.cover_photo_url

# Timestamps
if time_format == 'integer'
  json.created_at user.created_at_as_i
  json.updated_at user.updated_at_as_i
else
  json.created_at user.created_at
  json.updated_at user.updated_at
end
