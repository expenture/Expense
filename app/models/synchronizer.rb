class Synchronizer < ApplicationRecord
  # A unique code that should be defined in all synchronizers,
  # this should be a symbol
  CODE = nil
  # A region code that should be defined in all synchronizers,
  # this should be a symbol
  REGION_CODE = nil
  # A type that should be defined in all synchronizers,
  # this should be a symbol
  TYPE = nil
  # Specify the supported data collecting methods for each synchronizers
  COLLECT_METHODS = [].freeze
  # The display name that should be defined in all synchronizers
  NAME = ''.freeze
  # The description of the syncer that should be defined in all synchronizers
  DESCRIPTION = ''.freeze
  # The passcode description that should be defined in all synchronizers
  PASSCODE_INFO = {}.freeze
  # The statement of the running schedule of the synchronizer
  SCHEDULE_INFO = {}.freeze
  # An introduction about the email endpoint of the synchronizer
  EMAIL_ENDPOINT_INTRODUCTION = nil

  # The base class for Collector, Parser and Organizer
  class Worker
    extend Forwardable
    def_delegators :@synchronizer, :user_id, :user, :uid, :type, :enabled,
                   :name, :status,
                   :passcode_1, :passcode_2, :passcode_3, :passcode_4,
                   :last_collected_at, :last_parsed_at, :last_synced_at,
                   :collected_pages, :parsed_data, :accounts,
                   :account_identifiers,
                   :logger, :log_debug, :log_info, :log_error

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
    def run(level: :normal)
      raise NotImplementedError,
            "#{self.class.name}#run is not yet implemented!"
    end
  end

  # The organizer that should be implemented in all synchronizers
  # @abstract
  class Organizer < Worker
    # Run the organizer and update records in the database
    # @abstract
    def run(level: :normal)
      raise NotImplementedError,
            "#{self.class.name}#run is not yet implemented!"
    end
  end

  # Run the data collecting process of the syncer
  # (Step 1 of syncing)
  def run_collect(level: :normal)
    log_info "Running collect of level #{level}"
    collect_start
    collector.run(level: level)
    collect_done
    log_info "Done collect of level #{level}"
  rescue NoMethodError
    collect_done
    log_info "Skipping collect: no method"
  rescue NotImplementedError
    collect_done
    log_info "Skipping collect: not implemented"
  rescue Exception => e
    if e.is_a? ServiceAuthenticationError
      collect_faild(:bad_passcode)
      log_info "Bad passcode on running collect of level #{level}"
    else
      collect_faild
      log_error "Failed on running collect of level #{level}, exception: #{e}"
    end
    raise e
  end

  # Run the data parsing process of the syncer
  # (Step 2 of syncing)
  def run_parse(level: :normal)
    log_info "Running parse of level #{level}"
    parse_start
    parser.run(level: level)
    parse_done
    log_info "Done parse of level #{level}"
  rescue NotImplementedError
    raise NotImplementedError,
          "#{self.class.name}::Parser#run is not yet implemented!"
  rescue Exception => e
    parse_faild
    log_error "Failed on running parse of level #{level}, exception: #{e}"
    raise e
  end

  # Run the record organizing process of the syncer
  # (Step 3 of syncing)
  def run_organize(level: :normal)
    log_info "Running organize of level #{level}"
    organize_start
    organizer.run(level: level)
    organize_done
    log_info "Done organize of level #{level}"
  rescue NotImplementedError
    raise NotImplementedError,
          "#{self.class.name}::Organizer#run is not yet implemented!"
  rescue Exception => e
    organize_faild
    log_error "Failed on running organize of level #{level}, exception: #{e}"
    raise e
  end

  # Perform the sync in background worker
  def perform_sync(level: :normal)
    SynchronizerRunCollectJob.perform_later(synchronizer: self, level: level.to_s, auto_continue_syncing: true)
    log_info "Queued sync of level #{level}"
  end

  # Perform the sync if in schedule
  def perform_sync_if_in_schedule(time, level: :normal)
    return unless schedule_times.map { |t| Regexp.new(t.tr('*', '.')) }.map { |r| r.match(time) }.any?
    perform_sync(level: level)
  end

  def schedule_times
    self.class::SCHEDULE_INFO[self.schedule.to_sym][:times]
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

  def logger
    Rails.logger
  end

  def log_debug(message)
    logger.debug "#{self.class.name}: #{uid}: #{message}"
  end

  def log_info(message)
    logger.info "#{self.class.name}: #{uid}: #{message}"
  end

  def log_error(message)
    logger.error "#{self.class.name}: #{uid}: #{message}"
  end

  # Class methods for managing registered syncers
  class << self
    # Returns a hash of registered syncers with their code as the key
    def syncer_classes
      Dir[Rails.root.join("app/synchronizers/**/*.rb")].each { |f| load f } if Rails.env.development? || Rails.env.test?
      return @syncer_classes if @syncer_classes
      @syncer_classes ||= HashWithIndifferentAccess.new
      @syncer_classes
    end

    def syncer_classes_as_json
      Hash[Synchronizer.syncer_classes.map do |code, syncer|
        [code, {
          code: syncer::CODE,
          region_code: syncer::REGION_CODE,
          type: syncer::TYPE,
          collect_methods: syncer::COLLECT_METHODS,
          name: syncer::NAME,
          description: syncer::DESCRIPTION,
          schedules: syncer::SCHEDULE_INFO,
          passcodes: syncer::PASSCODE_INFO,
          email_endpoint_host: (syncer::COLLECT_METHODS.include?(:email) ? ENV['SYNCHRONIZER_RECEIVING_EMAIL_HOST'] : nil),
          email_endpoint_introduction: syncer::EMAIL_ENDPOINT_INTRODUCTION
        }]
      end]
    end

    # Registers a new syncer
    def register(syncer_class)
      @syncer_classes ||= HashWithIndifferentAccess.new
      @syncer_classes[syncer_class::CODE] = syncer_class

      # TODO: More rigorous validation

      if syncer_class::PASSCODE_INFO.present?
        raise "#{syncer_class.name}::PASSCODE_INFO should be a hash" unless syncer_class::PASSCODE_INFO.is_a? Hash
        syncer_class::PASSCODE_INFO.each_pair do |k, v|
          raise "#{syncer_class.name}::PASSCODE_INFO[#{k}] is invalid" unless v.is_a? Hash
          raise "#{syncer_class.name}::PASSCODE_INFO[#{k}][:name] must not be blank" unless v[:name].present?
          raise "#{syncer_class.name}::PASSCODE_INFO[#{k}][:description] must not be blank" unless v[:name].present?
          raise "#{syncer_class.name}::PASSCODE_INFO[#{k}][:name] must be a string" unless v[:name].is_a? String
          raise "#{syncer_class.name}::PASSCODE_INFO[#{k}][:description] must be a string" unless v[:description].is_a? String
          syncer_class.validates "passcode_#{k}", presence: true if v[:required]
          syncer_class.validates "passcode_#{k}", format: v[:format] if v[:format].present?
        end
      end

      if syncer_class::SCHEDULE_INFO.present?
        raise "#{syncer_class.name}::SCHEDULE_INFO should be a hash" unless syncer_class::SCHEDULE_INFO.is_a? Hash
        raise "#{syncer_class.name}::SCHEDULE_INFO has invalid keys" if syncer_class::SCHEDULE_INFO.keys.uniq.sort != [:normal, :high_frequency, :low_frequency].uniq.sort
        syncer_class::SCHEDULE_INFO.each_pair do |k, v|
          raise "#{syncer_class.name}::SCHEDULE_INFO[:#{k}] is invalid" unless v.is_a? Hash
          raise "#{syncer_class.name}::SCHEDULE_INFO[:#{k}][:times] must not be blank" unless v[:times].present?
          raise "#{syncer_class.name}::SCHEDULE_INFO[:#{k}][:times] must be a array" unless v[:times].is_a? Array
          raise "#{syncer_class.name}::SCHEDULE_INFO[:#{k}][:description] must not be blank" unless v[:description].present?
          v[:times].each do |t|
            raise "#{syncer_class.name}::SCHEDULE_INFO[:#{k}][:times] time #{t} is not a correct format" unless t.match(/[\d\*]{2}:[\d\*][0\*]/)
          end
        end
      end
    end

    # Schedule syncers to run in background workers for a specified time
    def schedule_syncers_for_time(time)
      logger.info "#{self.name}: Scheduling syncers for time: #{time}"

      enabled.find_each do |syncer|
        syncer.perform_sync_if_in_schedule(time)
      end
    end

    # Override Rails STI class finding
    # @api private
    def find_sti_class(type_name)
      return self if type_name == 'base'
      Synchronizer.syncer_classes[type_name]
    end

    # Override Rails STI class name
    # @api private
    def sti_name
      self::CODE
    end

    def logger
      Rails.logger
    end
  end

  # General ActiveRecord relations, validations and callbacks
  scope :enabled, -> { where(enabled: true) }
  belongs_to :user
  has_many :collected_pages, class_name: 'Synchronizer::CollectedPage',
                             primary_key: :uid, foreign_key: :synchronizer_uid
  has_many :parsed_data, class_name: 'Synchronizer::ParsedData',
                         primary_key: :uid, foreign_key: :synchronizer_uid
  has_many :accounts, class_name: 'SyncingAccount',
                      primary_key: :uid, foreign_key: :synchronizer_uid
  delegate :account_identifiers, to: :user, prefix: false
  validates :user, :uid, :name, :type, presence: true
  validates :uid, uniqueness: true
  validates :schedule, inclusion: { in: %w(normal high_frequency low_frequency), message: "%{value} is not a valid schedule, must be one of: normal, high_frequency or low_frequency" }
  after_initialize :init_passcode_encrypt_salt

  # Virtual attrs for getting and setting plaintext passcodes
  1.upto(4) do |i|
    define_method "passcode_#{i}" do
      return nil unless self["encrypted_passcode_#{i}"]
      encrypted_data = Base64.decode64(self["encrypted_passcode_#{i}"])
      Encryptor.decrypt(encrypted_data, salt: passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: passcode_encrypt_salt)
    end

    define_method "passcode_#{i}=" do |passcode|
      return if passcode.blank?
      encrypted_data = Encryptor.encrypt(passcode, salt: passcode_encrypt_salt, key: ENV['SYNCER_PASSCODE_ENCRYPT_KEY'], iv: passcode_encrypt_salt)
      self["encrypted_passcode_#{i}"] = Base64.encode64(encrypted_data)
    end
  end

  def email_endpoint
    return nil unless self.class::COLLECT_METHODS.include?(:email)
    "#{uid}@#{ENV['SYNCHRONIZER_RECEIVING_EMAIL_HOST']}"
  end

  # Rewirte the getter of passcode_encrypt_salt to init the salt immediately
  # if the salt is blank
  def passcode_encrypt_salt
    salt = super
    return salt if salt.present?
    init_passcode_encrypt_salt
    super
  end

  # An error class used for raising while something isn't fully implemented
  # is called
  class NotImplementedError < StandardError
  end

  # An error class used for raising on synchronization while
  # authenticating failure (normally by incorrect passcodes)
  class ServiceAuthenticationError < StandardError
  end

  private

  def init_passcode_encrypt_salt
    return if self[:passcode_encrypt_salt].present?
    self.passcode_encrypt_salt = SecureRandom.hex(16)
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

  def collect_faild(reason = nil)
    if reason.present?
      self.status = reason
    else
      self.status = 'collect_error'
      self.last_errored_at = Time.now
    end
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
    self.last_errored_at = Time.now
    save!
  end

  def organize_start
    self.status = 'organizing'
    save!
  end

  def organize_done
    self.status = 'synced'
    self.last_synced_at = last_parsed_at
    save!
  end

  def organize_faild
    self.status = 'organize_error'
    self.last_errored_at = Time.now
    save!
  end
end
