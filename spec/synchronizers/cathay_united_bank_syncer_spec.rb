require 'rails_helper'

RSpec.describe CathayUnitedBankSyncer, type: :model do
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:passcode_1) }
  it { is_expected.to validate_presence_of(:passcode_2) }
  it { is_expected.to validate_presence_of(:passcode_3) }
  it { is_expected.not_to validate_presence_of(:passcode_4) }

  it "should validate that :passcode_1 is a format of 身分證字號" do
    is_expected.to allow_value('A000000000', 'E123456789').for(:passcode_1)
    is_expected.not_to allow_value('1234567890', 'A1234').for(:passcode_1)
  end

  it "should validate that :passcode_2 is a format of 4 位阿拉伯數字" do
    is_expected.to allow_value('3827', '5837').for(:passcode_2)
    is_expected.not_to allow_value('37232', 'a837').for(:passcode_2)
  end

  it "should validate that :passcode_3 is a format of 6~12 位英數字混合" do
    is_expected.to allow_value('abdu38', 'fog383', 'dk26938bj381').for(:passcode_3)
    is_expected.not_to allow_value('abc12', 'dj49fjw43874iu3s8d').for(:passcode_3)
  end

  describe "#run_collect", integration: true do
    context "with incorrect passcodes" do
      let(:syncer) { CathayUnitedBankSyncer.create!(uid: SecureRandom.uuid, user: user, name: 'Test Syncer With Incorrect Passcodes', passcode_1: 'A123456789', passcode_2: '1234', passcode_3: 'wrong1234') }

      it "throws a ServiceAuthenticationError and sets the status to bad_passcode" do
        expect { syncer.run_collect }.to raise_error(Synchronizer::ServiceAuthenticationError)
        expect(syncer.status).to eq('bad_passcode')
      end
    end
  end
end
