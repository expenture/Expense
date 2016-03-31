require "rails_helper"

describe "WebHook Endpoints: Syncer Receiving: Mailgun" do
  describe "POST /webhook_endpoints/syncer_receiving/mailgun" do
    let(:synchronizer) { create(:synchronizer, type: :apple_receipt) }
    let(:syncer_uid) { synchronizer.uid }
    subject(:request) do
      post '/webhook_endpoints/syncer_receiving/mailgun', params: {
        'body-html' => '<p>Hello!</p>',
        'recipient' => "#{syncer_uid}@syncers.net"
      }
    end

    it "pass the email into the #receive method of the syncer collector and returns status 200" do
      request

      # we test the "pass the email into the #receive method" by actually
      # checking if the page is saved
      expect(synchronizer.collected_pages.last).not_to be_nil
      expect(synchronizer.collected_pages.last.body).to eq('<p>Hello!</p>')

      expect(response).to be_success
      expect(response.status).to eq(200)
    end

    context "the syncer does not exists" do
      let(:syncer_uid) { 'blablabla' }

      it "returns status 404" do
        request

        expect(response).not_to be_success
        expect(response.status).to eq(404)
      end
    end

    context "the collector #receive of the syncer is not implemented" do
      let(:synchronizer) { create(:synchronizer, type: :tw_einvoice) }

      it "returns status 400" do
        request

        expect(response).not_to be_success
        expect(response.status).to eq(400)
      end
    end
  end
end
