class UsersController < ApplicationController

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to edit_user_path(@user), notice: "User created successfully."
    else
      redirect_to edit_user_path(@user), alert: @user.errors.full_messages
    end
  end

  private

    def user_params
      params.require(:user).permit(:email, :phone, car_ids: [])
    end

end
