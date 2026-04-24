class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?

  private

  # Use as `before_action :require_admin!` on admin-only actions/controllers.
  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: "Admins only."
  end
end
