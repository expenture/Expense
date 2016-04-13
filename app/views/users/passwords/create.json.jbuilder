if @error
  json.status 'error'
  json.error @error
else
  json.status 'reset_password_email_sent'
  json.user @user, partial: '_models/user', as: :user
end
