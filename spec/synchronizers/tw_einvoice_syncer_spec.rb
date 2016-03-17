require 'rails_helper'

RSpec.describe TWEInvoiceSyncer, type: :model do
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:passcode_1) }
  it { is_expected.to validate_presence_of(:passcode_2) }
  it { is_expected.not_to validate_presence_of(:passcode_3) }
  it { is_expected.not_to validate_presence_of(:passcode_4) }

  it "should validate that :passcode_1 is a format of mobile number" do
    is_expected.to allow_value('0900000000', '0987654321').for(:passcode_1)
    is_expected.not_to allow_value('1234', '0000000000').for(:passcode_1)
  end

  describe "#run_collect", integration: true do
    context "with incorrect passcodes" do
      let(:syncer) { TWEInvoiceSyncer.create!(uid: SecureRandom.uuid, user: user, name: 'Test Syncer With Incorrect Passcodes', passcode_1: '0900000000', passcode_2: 'something_wrong') }

      it "throws a ServiceAuthenticationError and sets the status to bad_passcode" do
        expect { syncer.run_collect }.to raise_error(Synchronizer::ServiceAuthenticationError)
        expect(syncer.status).to eq('bad_passcode')
      end
    end
  end
end
