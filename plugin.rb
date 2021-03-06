# name: Community SSO Redirect
# about: Create a cross subdomain cookie for Community and Campus
# version: 0.6.6
# authors: Harold Sanchez Balaguera and Gustavo Scanferla
# url: https://bitbucket.org/amazingacademy/community-sso-redirect-plugin/

after_initialize do
	SessionController.class_eval do

		require_dependency 'single_sign_on'

		skip_before_filter :check_xhr, only: ['sso', 'sso_login', 'become', 'sso_provider']

  	def sso
      return_path = if params[:return_path]
        params[:return_path]
      elsif session[:destination_url]
        URI::parse(session[:destination_url]).path
      else
        path('/')
      end

      unless cookies[:amazing_return_url]
        cookies[:amazing_return_url] = { value: return_path, expires: 1.hour.from_now }
        #cookies[:amazing_return_url] = { value: cookies[:destination_url], expires: 1.hour.from_now }
      end


      Rails.logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@ return_url: #{cookies[:amazing_return_url]}"
      puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@ return_url: #{cookies[:amazing_return_url]}"

      if SiteSetting.enable_sso?
        redirect_to DiscourseSingleSignOn.generate_url(return_path)
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

    Rails.logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@ return_url 2: #{cookies[:amazing_return_url]}"
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@ return_url 2: #{cookies[:amazing_return_url]}"


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

        return_path = cookies[:amazing_return_url]
        cookies.delete :amazing_return_url

        Rails.logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@ return_url 3 #{return_path}"
        puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@ return_url 3 #{return_path}"

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