class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :enforce_password_change!
  layout :resolve_layout

  helper_method :current_user, :user_signed_in?

  private

  def resolve_layout
    devise_controller? ? "devise" : "application"
  end

  # Use as `before_action :require_admin!` on admin-only actions/controllers.
  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: "Admins only."
  end

  # When admins create or reset a user, we set must_change_password=true.
  # Force them to change before they can do anything else (except sign out
  # and the change-password page itself).
  def enforce_password_change!
    return unless user_signed_in?
    return unless current_user.must_change_password?
    return if devise_controller?
    return if controller_path == "users/password_changes"

    redirect_to edit_password_change_path, alert: "Please choose a new password before continuing."
  end
end
