# name: Community SSO Redirect Plugin
# about: Create a cross subdomain cookie for Community and Campus 
# version: 0.5
# authors: Harold Sanchez Balaguera

after_initialize do
	SessionController.class_eval do

		require_dependency 'single_sign_on'

		skip_before_filter :check_xhr, only: ['sso', 'sso_login', 'become', 'sso_provider']

		def sso
			if SiteSetting.enable_sso
				url = DiscourseSingleSignOn.generate_url(params[:return_path] || path('/'))
				return_url = Base64.encode64(CGI::escape(request.host))

				if cookies[:destination_url]
					return_url = Base64.encode64(CGI::escape(cookies[:destination_url]))
				end

				redirect_to "#{url}&return=#{return_url}"
			else
				render nothing: true, status: 404
			end
		end
	end
end