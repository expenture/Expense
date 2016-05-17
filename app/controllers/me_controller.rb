class MeController < ApplicationAPIController
  before_action :doorkeeper_authorize!

  def show
    @user = current_user
  end

  def update
    @user = current_user

    @user.assign_attributes(user_params)

    if @user.save
      render status: status
    else
      @error = Error.new(@user.errors)
      render status: @error.status
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
