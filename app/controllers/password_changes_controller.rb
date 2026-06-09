# Change the password while logged in (requires the current password).
class PasswordChangesController < ApplicationController
  def update
    user = Current.user
    unless user.authenticate(params[:current_password])
      return redirect_to edit_profile_path, alert: "Current password is incorrect."
    end

    if user.update(params.permit(:password, :password_confirmation))
      redirect_to profile_path, notice: "Password changed."
    else
      redirect_to edit_profile_path, alert: user.errors.full_messages.to_sentence
    end
  end
end
