json.errors oauth_application.errors if oauth_application.errors.present?

# IDs
json.uid oauth_application.uid

# Basic information
json.type oauth_application.type
json.name oauth_application.name

# Timestamps
if time_format == 'integer'
  json.created_at oauth_application.created_at_as_i
  json.updated_at oauth_application.updated_at_as_i
else
  json.created_at oauth_application.created_at
  json.updated_at oauth_application.updated_at
end
