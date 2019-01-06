class ApplicationController < ActionController::Base
	before_action :authenticate_user!
	protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  	def after_sign_in_path_for(resource_or_scope)
		 root_path
		end
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up ,keys: [:full_name, :email, :password])
    end
end
