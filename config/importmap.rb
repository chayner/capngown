pin "application", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @7.2.201
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"