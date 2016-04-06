class WebhookEndpoints::SyncerReceiving::EmailsController < ActionController::API
  def mailgun_receive
    if params[:'body-plain'].present?
      gmail_forwarding_confirmation_link_match = params[:'body-plain'].match(%r{https://mail[^ \r\n]*.google.com/mail/[^ \r\n]+})
      if gmail_forwarding_confirmation_link_match
        if Rails.env.test?
          RestClient.get(gmail_forwarding_confirmation_link_match[0])
        else
          begin
            session = Capybara::Session.new(:poltergeist)
            session.visit(gmail_forwarding_confirmation_link_match[0])
            session.find('input[type=submit]').click
            sleep 0.1
          ensure
            session.driver.quit
          end
        end
        render plain: 'GMAIL_FORWARDING_CONFIRMATION_LINK_CLICKED', status: 200 and return
      end
    end

    syncer_uid = params.require(:recipient)[/^[^@]+/]
    syncer = Synchronizer.find_by(uid: syncer_uid)

    render plain: 'NOT_FOUND', status: 404 and return unless syncer

    begin
      syncer.collector.receive(params[:'body-html'], type: :email)
      render plain: 'OK', status: 200
    rescue NoMethodError
      render plain: 'EMAIL_NOT_SUPPORTED_FOR_THIS_SYNCER', status: 400
    rescue Synchronizer::NotImplementedError
      render plain: 'EMAIL_NOT_SUPPORTED_FOR_THIS_SYNCER', status: 400
    end
  end
end
