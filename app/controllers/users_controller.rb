class UsersController < ApplicationAPIController
  def create
    @user = User.new(params.require(:user).permit(:email, :password, :password_confirmation))
    existing_unconfirmed_user = User.find_by(email: @user.email, confirmed_at: nil)
    existing_unconfirmed_user.destroy if existing_unconfirmed_user

    if @user.save
      render status: 201
    else
      @error = { message: @user.errors.full_messages.join(', ') }
      render status: 400
    end
  end
end
