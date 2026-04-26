module Users
  class PasswordChangesController < ApplicationController
    skip_before_action :enforce_password_change!

    def edit; end

    def update
      user = current_user
      if user.update_with_password(password_params)
        user.update!(must_change_password: false)
        bypass_sign_in(user)
        redirect_to root_path, notice: "Password updated."
      else
        flash.now[:alert] = user.errors.full_messages.to_sentence.presence || "Could not update password."
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end
  end
end
