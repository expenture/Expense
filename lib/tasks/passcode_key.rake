require File.expand_path('../../../config/environment', __FILE__)

desc "Generate passcode keypairs"
task :passcode_key do
  rsa_key = OpenSSL::PKey::RSA.new(1024)
  private_key = rsa_key.to_pem.split('-----')[2].tr("\n", '-')[1..-2]
  public_key = rsa_key.public_key.to_pem.split('-----')[2].tr("\n", '-')[1..-2]
  puts "Private key: #{private_key}"
  puts "-----"
  private_key.scan(/.{1,254}/).each_with_index do |private_key_part, i|
    puts "Private key part #{i + 1}: #{private_key_part}"
  end
  puts "-----"
  puts "Public key: #{public_key}"
end
