json.key_format!(camelize: :lower) if camelize_keys

json.error @error if @error

json.user @user, partial: 'me/me', as: :user
