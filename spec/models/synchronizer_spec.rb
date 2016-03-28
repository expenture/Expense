require 'rails_helper'

RSpec.describe Synchronizer, :type => :model do
  it "initializes the passcode_encrypt_salt on after initialize" do
    syncer = Synchronizer.new
    expect(syncer.passcode_encrypt_salt).not_to be_blank

    salt = '702c19474ba78bd8'
    syncer = Synchronizer.new(passcode_encrypt_salt: salt)
    expect(syncer.passcode_encrypt_salt).to eq(salt)
  end

  it "has abstract collector, parser and organizer with run methods not implemented" do
    syncer = create(:synchronizer)
    expect { syncer.collector.run }.to raise_error(Synchronizer::NotImplementedError)
    expect { syncer.collector.receive('') }.to raise_error(Synchronizer::NotImplementedError)
    expect { syncer.parser.run }.to raise_error(Synchronizer::NotImplementedError)
    expect { syncer.organizer.run }.to raise_error(Synchronizer::NotImplementedError)
  end

  describe "#passcode_1" do
    it "gets the decrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_1 = PasscodeEncryptingService.encrypt(passcode, salt: syncer.passcode_encrypt_salt)

      expect(syncer.passcode_1).to eq(passcode)
    end
  end

  describe "#passcode_1=" do
    it "sets the encrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_1 = passcode

      expect(PasscodeEncryptingService.decrypt(syncer.encrypted_passcode_1, salt: syncer.passcode_encrypt_salt)).to eq(passcode)
    end
  end

  describe "#passcode_2" do
    it "gets the decrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_2 = PasscodeEncryptingService.encrypt(passcode, salt: syncer.passcode_encrypt_salt)

      expect(syncer.passcode_2).to eq(passcode)
    end
  end

  describe "#passcode_2=" do
    it "sets the encrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_2 = passcode

      expect(PasscodeEncryptingService.decrypt(syncer.encrypted_passcode_2, salt: syncer.passcode_encrypt_salt)).to eq(passcode)
    end
  end

  describe "#passcode_3" do
    it "gets the decrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_3 = PasscodeEncryptingService.encrypt(passcode, salt: syncer.passcode_encrypt_salt)

      expect(syncer.passcode_3).to eq(passcode)
    end
  end

  describe "#passcode_3=" do
    it "sets the encrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_3 = passcode

      expect(PasscodeEncryptingService.decrypt(syncer.encrypted_passcode_3, salt: syncer.passcode_encrypt_salt)).to eq(passcode)
    end
  end

  describe "#passcode_4" do
    it "gets the decrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_4 = PasscodeEncryptingService.encrypt(passcode, salt: syncer.passcode_encrypt_salt)

      expect(syncer.passcode_4).to eq(passcode)
    end
  end

  describe "#passcode_4=" do
    it "sets the encrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_4 = passcode

      expect(PasscodeEncryptingService.decrypt(syncer.encrypted_passcode_4, salt: syncer.passcode_encrypt_salt)).to eq(passcode)
    end
  end

  describe "#run_collect" do
    let(:syncer) { create(:synchronizer) }

    it "does not raise an error if its collector#run is not defined" do
      expect { syncer.run_collect }.not_to raise_error
    end

    context "no collect step" do
      before do
        allow_any_instance_of(Synchronizer::Collector).to receive(:run).and_raise(NoMethodError)
      end

      it "sets the status to 'collected'" do
        syncer.run_collect
        syncer.reload
        expect(syncer.status).to eq('collected')
      end
    end

    context "collect success" do
      before do
        allow_any_instance_of(Synchronizer::Collector).to receive(:run)
      end

      it "sets the status to 'collected'" do
        syncer.run_collect
        syncer.reload
        expect(syncer.status).to eq('collected')
      end

      it "sets the last_collected_at datetime" do
        syncer.run_collect
        syncer.reload
        expect(syncer.last_collected_at).not_to be_blank
      end
    end

    context "collect fail" do
      before do
        allow_any_instance_of(Synchronizer::Collector).to receive(:run).and_raise
      end

      it "sets the status to 'collect_error'" do
        expect { syncer.run_collect }.to raise_error
        syncer.reload
        expect(syncer.status).to eq('collect_error')
      end
    end

    context "collect fail due to bad passcodes" do
      before do
        allow_any_instance_of(Synchronizer::Collector).to receive(:run).and_raise(Synchronizer::ServiceAuthenticationError)
      end

      it "sets the status to 'bad_passcode'" do
        expect { syncer.run_collect }.to raise_error
        syncer.reload
        expect(syncer.status).to eq('bad_passcode')
      end
    end
  end

  describe "#run_parse" do
    let(:syncer) { create(:synchronizer) }

    it "raise an error if its collector#run is not defined" do
      expect { syncer.run_parse }.to raise_error(Synchronizer::NotImplementedError)
    end

    context "parse success" do
      before do
        allow_any_instance_of(Synchronizer::Parser).to receive(:run)
      end

      it "sets the status to 'parsed'" do
        syncer.run_parse
        syncer.reload
        expect(syncer.status).to eq('parsed')
      end

      it "sets the last_parsed_at datetime" do
        syncer.last_collected_at = Time.now
        syncer.run_parse
        syncer.reload
        expect(syncer.last_parsed_at).to eq(syncer.last_collected_at)
      end
    end

    context "parse fail" do
      before do
        allow_any_instance_of(Synchronizer::Parser).to receive(:run).and_raise
      end

      it "sets the status to 'parse_error'" do
        expect { syncer.run_parse }.to raise_error
        syncer.reload
        expect(syncer.status).to eq('parse_error')
      end
    end
  end

  describe "#run_organize" do
    let(:syncer) { create(:synchronizer) }

    it "raise an error if its collector#run is not defined" do
      expect { syncer.run_organize }.to raise_error(Synchronizer::NotImplementedError)
    end

    context "organize success" do
      before do
        allow_any_instance_of(Synchronizer::Organizer).to receive(:run)
      end

      it "sets the status to 'synced'" do
        syncer.run_organize
        syncer.reload
        expect(syncer.status).to eq('synced')
      end

      it "sets the last_synced_at datetime" do
        syncer.last_parsed_at = Time.now
        syncer.run_organize
        syncer.reload
        expect(syncer.last_synced_at).to eq(syncer.last_parsed_at)
      end
    end

    context "organize fail" do
      before do
        allow_any_instance_of(Synchronizer::Organizer).to receive(:run).and_raise
      end

      it "sets the status to 'organize_error'" do
        expect { syncer.run_organize }.to raise_error
        syncer.reload
        expect(syncer.status).to eq('organize_error')
      end
    end
  end

  describe "#perform_sync" do
    let(:syncer) { create(:synchronizer) }
    before do
      allow_any_instance_of(Synchronizer::Collector).to receive(:run)
      allow_any_instance_of(Synchronizer::Parser).to receive(:run)
      allow_any_instance_of(Synchronizer::Organizer).to receive(:run)
    end

    it "success if the syncer is in a performable status" do
      allow(SynchronizerRunCollectJob).to receive(:perform_later)

      %w(new bad_passcode collect_error parse_error organize_error synced).each do |status|
        syncer.status = status
        syncer.save!
        expect(syncer.perform_sync).to eq(true)
        expect(syncer.status).to eq('scheduled')

        syncer.status = status
        syncer.save!
        expect { syncer.perform_sync! }.not_to raise_error
        expect(syncer.status).to eq('scheduled')
      end
    end

    it "fails if the syncer is not in a performable status" do
      allow(SynchronizerRunCollectJob).to receive(:perform_later)

      %w(scheduled collecting collected parseing parsed organizing).each do |status|
        syncer.perform_sync
        syncer.status = status
        syncer.save!
        expect(syncer.perform_sync).to eq(false)

        syncer.status = status
        syncer.save!
        expect { syncer.perform_sync! }.to raise_error(Synchronizer::PerformSyncError)
      end
    end

    it "success if the syncer is not in a performable status but has timeouted" do
      allow(SynchronizerRunCollectJob).to receive(:perform_later)

      syncer.perform_sync
      syncer.status = 'collecting'
      syncer.save!
      Timecop.travel(3.hours.from_now)
      expect(syncer.perform_sync).to eq(true)
      expect(syncer.status).to eq('scheduled')
      Timecop.return
    end
  end
end
