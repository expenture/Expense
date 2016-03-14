require 'rails_helper'

RSpec.describe Synchronizer, :type => :model do
  it "initializes the passcode_encrypt_salt on after initialize" do
    syncer = Synchronizer.new
    expect(syncer.passcode_encrypt_salt).not_to be_blank

    salt = '702c19474ba78bd8'
    syncer = Synchronizer.new(passcode_encrypt_salt: salt)
    expect(syncer.passcode_encrypt_salt).to eq(salt)
  end

  describe "#passcode_1" do
    it "gets the decrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_1 = Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000'))

      expect(syncer.passcode_1).to eq(passcode)
    end
  end

  describe "#passcode_1=" do
    it "sets the encrypted passcode one" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_1 = passcode

      expect(syncer.encrypted_passcode_1).to eq(Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000')))
    end
  end

  describe "#passcode_2" do
    it "gets the decrypted passcode two" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_2 = Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000'))

      expect(syncer.passcode_2).to eq(passcode)
    end
  end

  describe "#passcode_2=" do
    it "sets the encrypted passcode two" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_2 = passcode

      expect(syncer.encrypted_passcode_2).to eq(Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000')))
    end
  end

  describe "#passcode_3" do
    it "gets the decrypted passcode three" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_3 = Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000'))

      expect(syncer.passcode_3).to eq(passcode)
    end
  end

  describe "#passcode_3=" do
    it "sets the encrypted passcode three" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_3 = passcode

      expect(syncer.encrypted_passcode_3).to eq(Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000')))
    end
  end

  describe "#passcode_4" do
    it "gets the decrypted passcode four" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.encrypted_passcode_4 = Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000'))

      expect(syncer.passcode_4).to eq(passcode)
    end
  end

  describe "#passcode_4=" do
    it "sets the encrypted passcode four" do
      syncer = Synchronizer.new
      passcode = "hi! I'm the code"
      syncer.passcode_4 = passcode

      expect(syncer.encrypted_passcode_4).to eq(Base64.encode64(Encryptor.encrypt(passcode, salt: syncer.passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: '000000000000')))
    end
  end
end
