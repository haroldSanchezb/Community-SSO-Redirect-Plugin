# name: Community SSO Redirect Plugin
# about: Create a cross subdomain cookie for Community and Campus 
# version: 0.1
# authors: Harold Sanchez Balaguera

after_initialize do
	SessionController.class_eval do

		require_dependency 'single_sign_on'

		skip_before_filter :check_xhr, only: ['sso', 'sso_login', 'become', 'sso_provider', 'sso_redirect']

		def sso_redirect
			user_cookie = cookies[:_t]

			unless user_cookie
				nonce = DiscourseSingleSignOn.generate_url(params[:return_path] || '/')
				uri_array = Rack::Utils.parse_query(nonce)

				render json: uri_array

				# return_url = Base64.encode64(CGI::escape(request.host))

				# if cookies[:destination_url]
					# return_url = Base64.encode64(CGI::escape(cookies[:destination_url]))
				# end

				# sso_login_url = SiteSetting.sso_redirect_login

				# redirect_to "#{sso_login_url}?sso=#{sso}&sig=#{sig}&return=#{return_url}"
			else 
				redirect_to "/"
			end
		end
	end

	Discourse::Application.routes.append do
		get "session/sso_sign" => "session#sso_redirect"
	end
end