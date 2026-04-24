class User < ApplicationRecord
  # Devise modules in use:
  # - :database_authenticatable — email + password sign-in
  # - :recoverable — admin can reset passwords (no mailer; via rake task)
  # - :rememberable — "remember me" cookie
  # - :validatable — email + password validations
  #
  # Intentionally NOT enabled:
  # - :registerable — sign-up is invite-only (admin creates accounts)
  # - :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum role: { volunteer: 0, admin: 1 }

  # Hierarchy: admin can do anything a volunteer can.
  # Override the enum-generated `volunteer?` so admins also report true.
  def volunteer?
    admin? || role == "volunteer"
  end
end
