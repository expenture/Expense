class Synchronizer < ApplicationRecord
  # A unique code that should be defined in all synchronizers,
  # this should be a symbol
  CODE = nil
  # A region code that should be defined in all synchronizers,
  # this should be a symbol
  REGION_CODE = nil
  # The display name that should be defined in all synchronizers
  NAME = ''.freeze
  # The description of the syncer that should be defined in all synchronizers
  DESCRIPTION = ''.freeze
  # The passcode description that should be defined in all synchronizers
  PASSCODE_INFO = {}.freeze

  # The base class for Collector, Parser and Organizer
  class Worker
    extend Forwardable
    def_delegators :@synchronizer, :user_id, :user, :uid, :type, :enabled,
                   :name, :status,
                   :passcode_1, :passcode_2, :passcode_3, :passcode_4,
                   :last_collected_at, :last_parsed_at, :last_synced_at,
                   :collected_pages

    def initialize(synchronizer)
      @synchronizer = synchronizer
    end
  end

  # The collector that should be implemented in all synchronizers
  # @abstract
  class Collector < Worker
    # Run the collector and collects the data, save them for further parsing
    # @param [Symbol] level the level of data to collect
    #                       (+:normal+, +:light+ or +:complete+)
    # @abstract
    def run(level: :normal)
      raise NotImplementedError,
            "#{self.class.name}#run is not yet implemented!"
    end

    # Called when data should be send in initiatively, save it
    # for further parsing
    # @abstract
    def receive(data, type: nil)
      raise NotImplementedError,
            "The #receive method is not yet implemented for this collector!"
    end
  end

  # The parser that should be implemented in all synchronizers
  # @abstract
  class Parser < Worker
    # Run the parser and parses the unparse collected data, save the parsed
    # data for further organizing
    # @abstract
    def run
      raise NotImplementedError,
            "#{self.class.name}#run is not yet implemented!"
    end
  end

  # The organizer that should be implemented in all synchronizers
  # @abstract
  class Organizer < Worker
    # Run the organizer and update records in the database
    # @abstract
    def run
      raise NotImplementedError,
            "#{self.class.name}#run is not yet implemented!"
    end
  end

  # Run the data collecting process of the syncer
  # (Step 1 of syncing)
  def run_collect(level: :normal)
    collect_start
    collector.run(level: level)
    collect_done
  rescue NotImplementedError
    raise NotImplementedError,
          "#{self.class.name}::Collector#run is not yet implemented!"
  rescue Exception => e
    collect_faild
    raise e
  end

  # Run the data parsing process of the syncer
  # (Step 2 of syncing)
  def run_parse
    parse_start
    parser.run
    parse_done
  rescue NotImplementedError
    raise NotImplementedError,
          "#{self.class.name}::Parser#run is not yet implemented!"
  rescue Exception => e
    parse_faild
    raise e
  end

  # Run the record organizing process of the syncer
  # (Step 3 of syncing)
  def run_organize
    organize_start
    organizer.run
    organize_done
  rescue NotImplementedError
    raise NotImplementedError,
          "#{self.class.name}::Organizer#run is not yet implemented!"
  rescue Exception => e
    organize_faild
    raise e
  end

  # Returns the +Collector+ instance of the syncer
  def collector
    @collector ||= self.class::Collector.new(self)
  end

  # Returns the +Parser+ instance of the syncer
  def parser
    @parser ||= self.class::Parser.new(self)
  end

  # Returns the +Organizer+ instance of the syncer
  def organizer
    @organizer ||= self.class::Organizer.new(self)
  end

  # Class methods for managing registered syncers
  class << self
    # Returns a hash of registered syncers with their code as the key
    def syncer_classes
      return @syncer_classes if @syncer_classes
      @syncer_classes ||= HashWithIndifferentAccess.new
      Dir[Rails.root.join("app/synchronizers/**/*.rb")].each { |f| require f }
      @syncer_classes
    end

    # Registers a new syncer
    def register(syncer_class)
      @syncer_classes ||= HashWithIndifferentAccess.new
      @syncer_classes[syncer_class::CODE] = syncer_class

      if syncer_class::PASSCODE_INFO.is_a? Hash
        syncer_class::PASSCODE_INFO.each_pair do |k, v|
          next unless v.is_a? Hash
          next unless v[:required]
          syncer_class.validates "passcode_#{k}", presence: true
        end
      end
    end

    # Override Rails STI class finding
    # @api private
    def find_sti_class(type_name)
      Synchronizer.syncer_classes[type_name]
    end

    # Override Rails STI class name
    # @api private
    def sti_name
      self::CODE
    end
  end

  # General ActiveRecord relations, validations and callbacks
  belongs_to :user
  belongs_to :account,
             primary_key: :uid, foreign_key: :account_uid
  has_many :collected_pages, class_name: 'Synchronizer::CollectedPage',
                             primary_key: :uid, foreign_key: :synchronizer_uid
  has_many :parsed_data, class_name: 'Synchronizer::ParsedData',
                         primary_key: :uid, foreign_key: :synchronizer_uid
  validates :user, :uid, :name, presence: true
  validates :uid, uniqueness: true
  after_initialize :init_passcode_encrypt_salt

  # Virtual attrs for getting and setting plaintext passcodes
  1.upto(4) do |i|
    define_method "passcode_#{i}" do
      return nil unless self["encrypted_passcode_#{i}"]
      encrypted_data = Base64.decode64(self["encrypted_passcode_#{i}"])
      Encryptor.decrypt(encrypted_data, salt: passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: passcode_encrypt_salt)
    end

    define_method "passcode_#{i}=" do |passcode|
      encrypted_data = Encryptor.encrypt(passcode, salt: passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: passcode_encrypt_salt)
      self["encrypted_passcode_#{i}"] = Base64.encode64(encrypted_data)
    end
  end

  # An error class used for raising while something isn't fully implemented
  # is called
  class NotImplementedError < StandardError
  end

  private

  def init_passcode_encrypt_salt
    self.passcode_encrypt_salt ||= SecureRandom.hex(16)
  end

  def collect_start
    self.status = 'collecting'
    save!
  end

  def collect_done
    self.status = 'collected'
    self.last_collected_at = Time.now
    save!
  end

  def collect_faild
    self.status = 'collect_error'
    save!
  end

  def parse_start
    self.status = 'parseing'
    save!
  end

  def parse_done
    self.status = 'parsed'
    self.last_parsed_at = last_collected_at
    save!
  end

  def parse_faild
    self.status = 'parse_error'
    save!
  end

  def organize_start
    self.status = 'organizing'
    save!
  end

  def organize_done
    self.status = 'done'
    self.last_synced_at = last_parsed_at
    save!
  end

  def organize_faild
    self.status = 'organize_error'
    save!
  end
end
