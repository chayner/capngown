namespace :admin do
  desc "Create a new admin user. Usage: bin/rails admin:create EMAIL=foo@bar.com PASSWORD=secret123"
  task create: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is required" }
    password = ENV.fetch("PASSWORD") { abort "PASSWORD is required (min 8 chars)" }

    if User.exists?(email: email)
      abort "User #{email} already exists. Use admin:reset_password to change the password or admin:promote to make them an admin."
    end

    user = User.create!(email: email, password: password, role: :admin)
    puts "Created admin: #{user.email} (id=#{user.id})"
  end

  desc "Promote an existing user to admin. Usage: bin/rails admin:promote EMAIL=foo@bar.com"
  task promote: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is required" }
    user = User.find_by!(email: email)
    user.update!(role: :admin)
    puts "Promoted #{user.email} to admin."
  end

  desc "Reset a user's password. Usage: bin/rails admin:reset_password EMAIL=foo@bar.com PASSWORD=newsecret123"
  task reset_password: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is required" }
    password = ENV.fetch("PASSWORD") { abort "PASSWORD is required (min 8 chars)" }

    user = User.find_by!(email: email)
    user.password = password
    user.password_confirmation = password
    user.save!
    puts "Reset password for #{user.email}."
  end

  desc "Create a volunteer user. Usage: bin/rails admin:invite_volunteer EMAIL=foo@bar.com PASSWORD=secret123"
  task invite_volunteer: :environment do
    email = ENV.fetch("EMAIL") { abort "EMAIL is required" }
    password = ENV.fetch("PASSWORD") { abort "PASSWORD is required (min 8 chars)" }

    if User.exists?(email: email)
      abort "User #{email} already exists."
    end

    user = User.create!(email: email, password: password, role: :volunteer)
    puts "Created volunteer: #{user.email} (id=#{user.id})"
  end
end
