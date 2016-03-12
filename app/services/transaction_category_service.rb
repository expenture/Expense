# A class to deal with transaction categories, the instance can be initialize
# with a user, for user specific services
class TransactionCategoryService
  extend Forwardable

  def_delegator self, :validate_category_set

  def initialize(user)
    @user = user
  end

  # Gets the transaction category set
  def transaction_category_set
    return @transaction_category_set if @transaction_category_set
    @transaction_category_set = HashWithIndifferentAccess.new(
      @user.settings.user_transaction_category_set ||
      self.class.transaction_category_set
    )
  end

  # Sets the transaction category set
  def transaction_category_set=(new_set)
    new_set = HashWithIndifferentAccess.new(new_set)

    # Validate
    old_set = transaction_category_set
    new_set = validate_category_set(new_set, old_set)

    # Add back default categories if they're deleted
    self.class.transaction_category_set.each_pair do |parent_code, parent_category|
      if new_set[parent_code].blank?
        new_set[parent_code] = parent_category
        new_set[parent_code][:hidden] = true
      end

      parent_category[:categories].each_pair do |code, category|
        if new_set[parent_code][:categories][code].blank?
          new_set[parent_code][:categories][code] = category
          new_set[parent_code][:categories][code][:hidden] = true
        end
      end
    end

    new_set = validate_category_set(new_set, old_set)

    old_codes = self.class.transaction_category_codes(old_set)
    new_codes = self.class.transaction_category_codes(new_set)

    # Categories with transcations can't be deleted
    deleted_codes = old_codes - new_codes
    deleted_codes.each do |deleted_code|
      next unless @user.transactions.exists?(category_code: deleted_code)
      parent_code = self.class.parent_code_for(deleted_code, old_set)

      if new_set[parent_code].blank?
        new_set[parent_code] = old_set[parent_code]
        new_set[parent_code][:categories] = HashWithIndifferentAccess.new({})
      end

      new_set[parent_code][:categories][deleted_code] = old_set[parent_code][:categories][deleted_code]
    end

    @user.settings.user_transaction_category_set = new_set
    @transaction_category_set = new_set
  end

  # Return the category codes
  def transaction_category_codes
    self.class.transaction_category_codes(transaction_category_set)
  end

  # Return the available (not hidden) category codes
  def available_transaction_category_codes
    self.class.available_transaction_category_codes(transaction_category_set)
  end

  # Conjecture a category_code by the given words, datetime and location
  def categorize(words, datetime: nil, latitude: nil, longitude: nil)
    code = classifier.classify(words).to_hash[:top_score_key]

    if code == 'meal' && datetime.is_a?(Time)
      if latitude && longitude
        timezone = Timezone::Zone.new latlon: [latitude, longitude]
        hour = timezone.time(datetime).hour
      else
        hour = datetime.hour
      end

      code = meal_name_from_hour(hour)
    end

    code
  end

  # Return an classifier instance for category_code conjecturing
  def classifier
    return @classifier if @classifier

    @classifier = OmniCat::Classifiers::Bayes.new

    transaction_categorization_codes.each do |c|
      @classifier.add_category c
    end
    @classifier.train 'other', 'other'

    train_data = transaction_categorization_cases.map { |o| { words: o.words, category_code: o.category_code } }.group_by { |h| h[:category_code] }
    d_max = train_data.map { |_k, v| v.length }.max || 2
    transaction_categorization_codes.each do |code|
      data = train_data[code] || []
      d_diff = d_max - data.length
      (d_diff / 1.01).to_i.times { data.push(words: code, category_code: code) }

      @classifier.train_batch code, JSON.parse(data.map { |d| d[:words].to_s }.to_json)
    end

    @classifier
  end

  private def transaction_categorization_codes
    ['other'] + available_transaction_category_codes.delete_if { |c| c == 'other' }
  end

  private def transaction_categorization_cases
    TransactionCategorizationCase.where(user: [@user, nil], category_code: transaction_categorization_codes)
  end

  private def meal_name_from_hour(hour)
    if hour.between?(4, 10)
      'breakfast'
    elsif hour.between?(10, 11)
      'brunch'
    elsif hour.between?(11, 14)
      'launch'
    elsif hour.between?(14, 16)
      'afternoon_tea'
    elsif hour.between?(16, 21)
      'dinner'
    else
      'supper'
    end
  end

  class << self
    # Gets the default transaction category set for all users of this app
    def transaction_category_set
      HashWithIndifferentAccess.new(Settings.transaction_category_set)
    end

    # Sets the default transaction category set for all users of this app
    def transaction_category_set=(transaction_category_set)
      transaction_category_set = HashWithIndifferentAccess.new(transaction_category_set)
      transaction_category_set = validate_category_set(transaction_category_set, Settings.transaction_category_set)
      Settings.transaction_category_set = transaction_category_set

      return Settings.transaction_category_set
    end

    # Return the category codes that a category set contains
    def transaction_category_codes(category_set = transaction_category_set)
      category_set.values.delete_if { |pc| !pc[:categories].is_a?(Hash) }.map { |pc| pc[:categories].keys }.reduce { |a, e| a.concat(e) } || []
    end

    # Return the available (not hidden) category codes that a
    # category set contains
    def available_transaction_category_codes(category_set = transaction_category_set)
      category_set.values.delete_if { |pc| !pc[:categories].is_a?(Hash) || pc[:hidden] }.map { |pc| pc[:categories].delete_if { |_k, v| v[:hidden] }.keys }.reduce { |a, e| a.concat(e) } || []
    end

    # Get the parent category code for a category
    def parent_code_for(code, category_set = transaction_category_set)
      category_set.each_pair do |parent_code, parent_category|
        return parent_code if parent_category[:categories].keys.include?(code)
      end

      return nil
    end

    # Return the validated category set, remove or use old data for
    # invalid records
    def validate_category_set(new_category_set, old_category_set)
      return old_category_set unless new_category_set.is_a?(HashWithIndifferentAccess)

      duplicated_codes = transaction_category_codes(new_category_set).group_by { |e| e }.select { |_k, v| v.size > 1 }.map(&:first)

      new_category_set.each_pair do |parent_code, parent_category|
        new_category_set[parent_code] =
          validate_parent_category parent_code, parent_category,
                                   old_category_set: old_category_set,
                                   duplicated_codes: duplicated_codes
      end

      new_category_set = new_category_set.delete_if { |_k, v| v.blank? }
    end

    private def validate_parent_category(parent_code, parent_category, old_category_set: nil, duplicated_codes: [])
      # Validate the parent category
      if parent_category.is_a?(HashWithIndifferentAccess) &&
         parent_category[:name].present? &&
         parent_category[:name].is_a?(String) &&
         parent_category[:priority].present? &&
         (parent_category[:priority] = parent_category[:priority].to_i) &&
         parent_category[:priority].is_a?(Integer) &&
         (parent_category[:categories] ||= HashWithIndifferentAccess.new) &&
         parent_category[:categories].is_a?(HashWithIndifferentAccess)

        # Delete invalid attributes
        parent_category = parent_category.delete_if { |k, _v| !%w(name priority categories hidden).include? k }

        # Validate each category
        parent_category[:categories].each_pair do |code, category|
          parent_category[:categories][code] =
            validate_category parent_code, code, category,
                              old_category_set: old_category_set,
                              duplicated_codes: duplicated_codes
        end
        parent_category[:categories] = parent_category[:categories].delete_if { |_k, v| v.blank? }

      # The parent category is invalid
      else
        # Ignore the change, or clear it
        if old_category_set[parent_code]
          parent_category = old_category_set[parent_code]
        else
          parent_category = nil
        end
      end

      parent_category
    end

    private def validate_category(parent_code, code, category, old_category_set: nil, duplicated_codes: [])
      # Remove duplications
      return nil if duplicated_codes.include?(code) &&
                    parent_code != parent_code_for(code, old_category_set)

      # Validate the category
      if category.is_a?(HashWithIndifferentAccess) &&
         category[:name].present? &&
         category[:name].is_a?(String) &&
         category[:priority].present? &&
         (category[:priority] = category[:priority].to_i) &&
         category[:priority].is_a?(Integer)

        # Delete invalid attributes
        category.delete_if { |k, _v| !%w(name priority hidden).include? k }

      # The category is invalid
      else
        # Ignore the change, or clear it
        if old_category_set[parent_code] &&
           old_category_set[parent_code][:categories] &&
           old_category_set[parent_code][:categories][code]

          category = old_category_set[parent_code][:categories][code]
        else
          category = nil
        end
      end

      category
    end

    # Returns the general transaction categorization codes
    def transaction_categorization_codes
      ['other'] + transaction_category_codes.delete_if { |c| c == 'other' } + ['meal']
    end

    # Returns the general transaction categorization cases
    def transaction_categorization_cases
      TransactionCategorizationCase.where(user: nil, category_code: transaction_categorization_codes)
    end
  end

  # Define the default transaction categories which will provided by the app
  # for user's predefined category set
  DEFAULT_TRANSACTION_CATEGORY_SET = HashWithIndifferentAccess.new(
    personal_finance: {
      name: "Personal Finance",
      priority: 1,
      categories: {
        self_account_transfer: {
          name: "Self Account Transfer",
          priority: 1
        },
        credit_card_bill: {
          name: "Credit Card Bill",
          priority: 2
        }
      }
    },
    food: {
      name: "Food",
      priority: 2,
      categories: {
        breakfast: {
          name: "Breakfast",
          priority: 1
        },
        launch: {
          name: "Launch",
          priority: 2
        },
        dinner: {
          name: "Dinner",
          priority: 3
        },
        brunch: {
          name: "Brunch",
          priority: 4
        },
        afternoon_tea: {
          name: "Afternoon Tea",
          priority: 5
        },
        supper: {
          name: "Supper",
          priority: 6
        },
        meal: {
          name: "Meal",
          priority: 7
        },
        drinks: {
          name: "Drinks",
          priority: 8
        },
        snacks: {
          name: "Snacks",
          priority: 9
        }
      }
    }
  )
end
