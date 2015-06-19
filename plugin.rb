# name: Community SSO Redirect Plugin
# about: Create a cross subdomain cookie for Community and Campus 
# version: 0.6
# authors: Harold Sanchez Balaguera

after_initialize do
	SessionController.class_eval do

		require_dependency 'single_sign_on'

		skip_before_filter :check_xhr, only: ['sso', 'sso_login', 'become', 'sso_provider']

		def sso
			if SiteSetting.enable_sso
				return_url = '/'

				if cookies[:destination_url]
					return_url = cookies[:destination_url].gsub! "http://#{Discourse.current_hostname}", ''
				end

				Rails.logger.info "return_url #{return_url}"

				redirect_to DiscourseSingleSignOn.generate_url(return_url)
			else
				render nothing: true, status: 404
			end
		end

		  def sso_login
    unless SiteSetting.enable_sso
      return render(nothing: true, status: 404)
    end

    sso = DiscourseSingleSignOn.parse(request.query_string)
    if !sso.nonce_valid?
      return render(text: I18n.t("sso.timeout_expired"), status: 419)
    end

    if ScreenedIpAddress.should_block?(request.remote_ip)
      return render(text: I18n.t("sso.unknown_error"), status: 500)
    end

    if cookies[:destination_url]
				return_path = cookies[:destination_url].gsub! "http://#{Discourse.current_hostname}", ''
		else 
    	return_path = sso.return_path
		end
		Rails.logger.info "return_path #{return_path}"

    sso.expire_nonce!

    begin
      if user = sso.lookup_or_create_user(request.remote_ip)

        if SiteSetting.must_approve_users? && !user.approved?
          if SiteSetting.sso_not_approved_url.present?
            redirect_to SiteSetting.sso_not_approved_url
          else
            render text: I18n.t("sso.account_not_approved"), status: 403
          end
          return
        elsif !user.active?
          activation = UserActivator.new(user, request, session, cookies)
          activation.finish
          session["user_created_message"] = activation.message
          redirect_to users_account_created_path and return
        else
          log_on_user user
        end

        # If it's not a relative URL check the host
        if return_path !~ /^\/[^\/]/
          begin
            uri = URI(return_path)
            return_path = path("/") unless uri.host == Discourse.current_hostname
          rescue
            return_path = path("/")
          end
        end

        redirect_to return_path
      else
        render text: I18n.t("sso.not_found"), status: 500
      end
    rescue => e
      details = {}
      SingleSignOn::ACCESSORS.each do |a|
        details[a] = sso.send(a)
      end
      Rails.logger.error "Failed to create or lookup user: #{e}\n\n#{details.map{|k,v| "#{k}: #{v}"}.join("\n")}"

      render text: I18n.t("sso.unknown_error"), status: 500
    end
  end


	end
end