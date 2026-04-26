class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.order(:email)
  end

  def new
    @user = User.new(role: :volunteer, active: true)
  end

  def create
    @user = User.new(create_params)
    @user.must_change_password = true
    if @user.save
      redirect_to admin_users_path, notice: "Created #{@user.email}. Share the temp password securely; they'll be required to change it on first sign-in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if user_params[:password].present?
      if @user.update(user_params.merge(must_change_password: true))
        redirect_to admin_users_path, notice: "Updated #{@user.email}. They will be prompted to change the new temp password on next sign-in."
      else
        render :edit, status: :unprocessable_entity
      end
    elsif @user.update(user_params.except(:password, :password_confirmation))
      redirect_to admin_users_path, notice: "Updated #{@user.email}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Soft-deactivate (or reactivate via toggle in update). DELETE flips active=false.
  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You can't deactivate yourself."
      return
    end
    @user.update!(active: false)
    redirect_to admin_users_path, notice: "Deactivated #{@user.email}."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def create_params
    params.require(:user).permit(:email, :role, :active, :password, :password_confirmation)
  end

  def user_params
    params.require(:user).permit(:email, :role, :active, :password, :password_confirmation)
  end
end
