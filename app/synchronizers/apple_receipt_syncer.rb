class AppleReceiptSyncer < Synchronizer
  CODE = :apple_receipt
  REGION_CODE = nil
  TYPE = :receipt
  COLLECT_METHODS = [:email].freeze
  NAME = 'Receipts from Apple'.freeze
  DESCRIPTION = 'Email receipts for the App Store, iTunes, iBooks from Apple inc.'.freeze
  SCHEDULE_INFO = {
    normal: {
      description: '每小時',
      times: %w(**:00)
    },
    high_frequency: {
      description: '每十分鐘',
      times: %w(**:00 **:10 **:20 **:30 **:40 **:50)
    },
    low_frequency: {
      description: '每天午夜',
      times: %w(00:00)
    }
  }.freeze
  EMAIL_ENDPOINT_INTRODUCTION = ''.freeze

  class Collector < Worker
    def receive(data, type: nil)
      case type
      when :email
        collected_pages.create!(body: data, attribute_1: 'email')
      else
        raise NotImplementedError,
              "The type #{type} is not supported!"
      end
    end
  end

  class Parser < Worker
    def run(level: :normal)
    end
  end

  class Organizer < Worker
    def run(level: :normal)
    end
  end

  Synchronizer.register(self)
end
