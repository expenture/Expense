class WebhookEndpoints::SyncerReceiving::EmailsController < ActionController::API
  def mailgun_receive
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
