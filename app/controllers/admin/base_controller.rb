class Admin::BaseController < ApplicationController
  before_action :require_admin!

  layout "admin"
end
