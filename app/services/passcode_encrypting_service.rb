module PasscodeEncryptingService
  cattr_accessor :disable_decrypt_mode

  class << self
    def encrypt(plain_passcode, salt: nil)
      encrypted_data = public_key.public_encrypt(plain_passcode + salt)
      Base64.encode64(encrypted_data)
    end

    def decrypt(encrypted_passcode, salt: nil)
      raise "Using #decrypt while PasscodeEncryptingService is in disable_decrypt_mode" if disable_decrypt_mode
      encrypted_data = Base64.decode64(encrypted_passcode)
      private_key.private_decrypt(encrypted_data).gsub(/#{salt}$/, '')
    end

    def public_key
      return @public_key if @public_key
      @public_key = OpenSSL::PKey::RSA.new("-----BEGIN PUBLIC KEY-----\n#{public_key_string.tr('-', "\n")}\n-----END PUBLIC KEY-----\n")
    end

    def private_key
      return @private_key if @private_key
      @private_key = OpenSSL::PKey::RSA.new("-----BEGIN RSA PRIVATE KEY-----\n#{private_key_string.tr('-', "\n")}\n-----END RSA PRIVATE KEY-----\n")
    end

    def public_key_string
      raise "The ENV SYNCER_PASSCODE_ENCRYPT_PUBLIC_KEY is not set! Can't encrypt passcodes." if ENV['SYNCER_PASSCODE_ENCRYPT_PUBLIC_KEY'].blank?
      ENV['SYNCER_PASSCODE_ENCRYPT_PUBLIC_KEY']
    end

    def private_key_string
      private_key_string = ENV['SYNCER_PASSCODE_ENCRYPT_PRIVATE_KEY'] || ''
      return private_key_string if private_key_string.present?

      10.times do |i|
        private_key_string += ENV["SYNCER_PASSCODE_ENCRYPT_PRIVATE_KEY_#{i}"] if ENV["SYNCER_PASSCODE_ENCRYPT_PRIVATE_KEY_#{i}"]
      end

      raise "The ENV SYNCER_PASSCODE_ENCRYPT_PRIVATE_KEY is not set! Can't decrypt passcodes." if private_key_string.blank?
      private_key_string
    end
  end
end
