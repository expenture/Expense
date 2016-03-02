require 'rails_helper'

RSpec.describe TransactionCategoryService, type: :service do
  before(:all) do
    H = HashWithIndifferentAccess
  end

  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe ".validate_category_set" do
    it "removes invalid parent categories" do
      # Invalid name
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {}
        },
        ipc: {
          name: 1,
          priority: 2,
          categories: {}
        }
      })
      old_cs = H.new({})
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs).not_to have_key('ipc')

      # Invalid categories
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {}
        },
        ipc: {
          name: "IPC",
          priority: 2,
          categories: 0.1
        }
      })
      old_cs = H.new({})
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs).not_to have_key('ipc')
    end

    it "ignores invalid parent categories" do
      # Invalid name
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {}
        },
        ipc: {
          name: 1,
          priority: 2,
          categories: {}
        }
      })
      old_cs = H.new({
        ipc: {
          name: "IPC",
          priority: 2,
          categories: {}
        }
      })
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs).to have_key('ipc')
      expect(cs['ipc']['name']).to eq('IPC')

      # Invalid categories
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {}
        },
        ipc: {
          name: "IPC",
          priority: 2,
          categories: 0.1
        }
      })
      old_cs = H.new({
        ipc: {
          name: "IPC",
          priority: 2,
          categories: {}
        }
      })

      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs).to have_key('ipc')
      expect(cs['ipc']['categories']).to eq({})
    end

    it "removes invalid params for parent categories" do
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {},
          hidden: false,
          what: 1
        }
      })
      old_cs = H.new({})
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs[:pc]).to have_key('name')
      expect(cs[:pc]).to have_key('priority')
      expect(cs[:pc]).to have_key('categories')
      expect(cs[:pc]).to have_key('hidden')
      expect(cs[:pc]).not_to have_key('what')
    end

    it "removes invalid categories" do
      # Invalid name
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {
            c: {
              name: "C",
              priority: 1
            },
            ic: {
              name: 1,
              priority: 2
            }
          }
        }
      })
      old_cs = H.new({})
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs['pc'][:categories]).to have_key('c')
      expect(cs['pc'][:categories]).not_to have_key('ic')
    end

    it "ignores invalid categories" do
      # Invalid name
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {
            c: {
              name: "C",
              priority: 1
            },
            ic: {
              name: 1,
              priority: 2
            }
          }
        }
      })
      old_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {
            c: {
              name: "C",
              priority: 1
            },
            ic: {
              name: "IC",
              priority: 2
            }
          }
        }
      })
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs['pc'][:categories]).to have_key('c')
      expect(cs['pc'][:categories]).to have_key('ic')
      expect(cs['pc'][:categories]['ic'][:name]).to eq("IC")
    end

    it "removes invalid params for parent categories" do
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {
            c: {
              name: "C",
              priority: 1,
              hidden: false,
              what: 1
            }
          }
        }
      })
      old_cs = H.new({})
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs['pc'][:categories]['c']).to have_key('name')
      expect(cs['pc'][:categories]['c']).to have_key('priority')
      expect(cs['pc'][:categories]['c']).to have_key('hidden')
      expect(cs['pc'][:categories]['c']).not_to have_key('what')
    end

    it "removes duplicated categories" do
      new_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {
            c: {
              name: "C",
              priority: 1
            }
          }
        },
        pc2: {
          name: "PC2",
          priority: 2,
          categories: {
            c: {
              name: "C2",
              priority: 1
            }
          }
        }
      })
      old_cs = H.new({
        pc: {
          name: "PC",
          priority: 1,
          categories: {
            c: {
              name: "C",
              priority: 1
            }
          }
        },
        pc2: {
          name: "PC2",
          priority: 2,
          categories: {
            c: {
              name: "C2",
              priority: 1
            }
          }
        }
      })
      cs = TransactionCategoryService.validate_category_set(new_cs, old_cs)

      expect(cs).to have_key('pc')
      expect(cs['pc'][:categories]).to have_key('c')
      expect(cs['pc2'][:categories]).not_to have_key('c')
    end
  end

  describe ".transaction_category_set" do
    it "gets and sets the default transaction categories" do
      transaction_category_set = {
        food: {
          name: "Food",
          priority: 1,
          categories: {
            breakfirst: {
              name: "Breakfirst",
              priority: 1
            },
            launch: {
              name: "Launch",
              priority: 2
            },
            dinner: {
              name: "Dinner",
              priority: 3
            }
          }
        },
        other: {
          name: "Other",
          priority: 2,
          categories: {
            other: {
              name: "Other",
              priority: 1
            }
          }
        }
      }

      TransactionCategoryService.transaction_category_set = transaction_category_set
      expect(TransactionCategoryService.transaction_category_set).to eq(H.new(transaction_category_set))
    end
  end

  describe "#transaction_category_set" do
    before(:all) do
      TransactionCategoryService.transaction_category_set = {
        dpc1: {
          name: "Default Parent Category 1",
          priority: 1,
          categories: {
            dc1: {
              name: "Default Category 1",
              priority: 1
            },
            dc2: {
              name: "Default Category 2",
              priority: 2
            }
          }
        },
        dpc2: {
          name: "Default Parent Category 2",
          priority: 2,
          categories: {
            dc3: {
              name: "Default Category 3",
              priority: 1
            },
            dc4: {
              name: "Default Category 4",
              priority: 2
            }
          }
        }
      }
    end

    let(:transaction_category_service) { TransactionCategoryService.new(user) }
    let(:transaction_category_service2) { TransactionCategoryService.new(user2) }

    it "returns the default category set by default" do
      expect(transaction_category_service.transaction_category_set).to eq(TransactionCategoryService.transaction_category_set)
    end

    it "sets the category set for the user" do
      new_cs = H.new({
        dpc1: {
          name: "Default Parent Category 1",
          priority: 1,
          categories: {
            dc1: {
              name: "Default Category 1",
              priority: 1
            },
            dc2: {
              name: "Default Category 2",
              priority: 2
            }
          }
        },
        dpc2: {
          name: "Default Parent Category 2",
          priority: 2,
          categories: {
            dc3: {
              name: "Default Category 3",
              priority: 2
            },
            dc4: {
              name: "Default Category 4",
              priority: 3
            },
            c5: {
              name: "Category 5",
              priority: 1
            }
          }
        },
        pc3: {
          name: "Parent Category 3",
          priority: 3,
          categories: {}
        }
      })
      transaction_category_service.transaction_category_set = new_cs
      expect(transaction_category_service.transaction_category_set).to eq(new_cs)
      expect(transaction_category_service2.transaction_category_set).to eq(TransactionCategoryService.transaction_category_set)
    end

    it "add backs default categories if deleted while updating" do
      new_cs = H.new({
        dpc1: {
          name: "Default Parent Category 1",
          priority: 1,
          categories: {
            nc1: {
              name: "New Category 1",
              priority: 100
            }
          }
        },
        pc3: {
          name: "Parent Category 3",
          priority: 3,
          categories: {
            dc1: {
              name: "Default Category 1",
              priority: 1
            }
          }
        }
      })
      transaction_category_service.transaction_category_set = new_cs

      updated_transaction_category_set = transaction_category_service.transaction_category_set
      expect(updated_transaction_category_set).to have_key('dpc1')
      expect(updated_transaction_category_set['dpc1'][:categories]).to have_key('dc1')
      expect(updated_transaction_category_set['dpc1'][:categories]).to have_key('dc2')
      expect(updated_transaction_category_set).to have_key('dpc2')
      expect(updated_transaction_category_set['dpc2'][:categories]).to have_key('dc3')
      expect(updated_transaction_category_set['dpc2'][:categories]).to have_key('dc4')
      expect(updated_transaction_category_set['pc3'][:categories]).not_to have_key('dc1')
      expect(updated_transaction_category_set['dpc1'][:categories]).to have_key('nc1')
    end

    it "add backs categories containing transactions if deleted while updating" do
      old_cs = H.new({
        dpc1: {
          name: "Default Parent Category 1",
          priority: 1,
          categories: {
            dc1: {
              name: "Default Category 1",
              priority: 1
            },
            dc2: {
              name: "Default Category 2",
              priority: 2
            },
            cht1: {
              name: "Category Having Transactions 1",
              priority: 100
            },
            c1: {
              name: "Category 1",
              priority: 200
            }
          }
        },
        dpc2: {
          name: "Default Parent Category 2",
          priority: 2,
          categories: {
            dc3: {
              name: "Default Category 3",
              priority: 1
            },
            dc4: {
              name: "Default Category 4",
              priority: 2
            },
            cht2: {
              name: "Category Having Transactions 2",
              priority: 100
            },
            c2: {
              name: "Category 2",
              priority: 200
            }
          }
        },
        pc3: {
          name: "Parent Category 3",
          priority: 3,
          categories: {
            cht3: {
              name: "Category Having Transactions 3",
              priority: 100
            },
            c3: {
              name: "Category 3",
              priority: 200
            }
          }
        },
        pc4: {
          name: "Parent Category 4",
          priority: 4,
          categories: {
            cht4: {
              name: "Category Having Transactions 4",
              priority: 100
            },
            c4: {
              name: "Category 4",
              priority: 200
            }
          }
        }
      })
      new_cs = H.new({
        dpc1: {
          name: "Default Parent Category 1",
          priority: 1,
          categories: {
            dc1: {
              name: "Default Category 1",
              priority: 1
            },
            dc2: {
              name: "Default Category 2",
              priority: 2
            }
          }
        },
        pc3: {
          name: "Parent Category 3",
          priority: 3,
          categories: {
            nc1: {
              name: "New Category 1",
              priority: 500
            }
          }
        }
      })

      transaction_category_service.transaction_category_set = old_cs
      user.accounts.last.transactions.create!(uid: 'a', amount: 1000, category_code: 'cht1')
      user.accounts.last.transactions.create!(uid: 'b', amount: 1000, category_code: 'cht2')
      user.accounts.last.transactions.create!(uid: 'c', amount: 1000, category_code: 'cht3')
      user.accounts.last.transactions.create!(uid: 'd', amount: 1000, category_code: 'cht4')
      transaction_category_service.transaction_category_set = new_cs

      updated_transaction_category_set = transaction_category_service.transaction_category_set
      expect(updated_transaction_category_set).to have_key('dpc1')
      expect(updated_transaction_category_set['dpc1'][:categories]).to have_key('dc1')
      expect(updated_transaction_category_set['dpc1'][:categories]).to have_key('dc2')
      expect(updated_transaction_category_set['dpc1'][:categories]).to have_key('cht1')
      expect(updated_transaction_category_set['dpc1'][:categories]).not_to have_key('c1')

      expect(updated_transaction_category_set).to have_key('dpc2')
      expect(updated_transaction_category_set['dpc2'][:categories]).to have_key('dc3')
      expect(updated_transaction_category_set['dpc2'][:categories]).to have_key('dc4')
      expect(updated_transaction_category_set['dpc2'][:categories]).to have_key('cht2')
      expect(updated_transaction_category_set['dpc2'][:categories]).not_to have_key('c2')

      expect(updated_transaction_category_set).to have_key('pc3')
      expect(updated_transaction_category_set['pc3'][:categories]).to have_key('nc1')
      expect(updated_transaction_category_set['pc3'][:categories]).to have_key('cht3')
      expect(updated_transaction_category_set['pc3'][:categories]).not_to have_key('c3')

      expect(updated_transaction_category_set).to have_key('pc4')
      expect(updated_transaction_category_set['pc4'][:categories]).to have_key('cht4')
      expect(updated_transaction_category_set['pc4'][:categories]).not_to have_key('c4')
    end
  end

  describe "#categorize" do
    before(:all) do
      TransactionCategoryService.transaction_category_set = {
        food: {
          name: "Food",
          priority: 1,
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
        },
        other: {
          name: "Other",
          priority: 2,
          categories: {
            other: {
              name: "Other",
              priority: 1
            },
            uneatable: {
              name: "Uneatable",
              priority: 2
            }
          }
        }
      }

      create :transaction_categorization_case, words: 'Sandwich', category_code: 'meal'
      create :transaction_categorization_case, words: 'Steak', category_code: 'meal'
      create :transaction_categorization_case, words: 'Pork Chop', category_code: 'meal'
      create :transaction_categorization_case, words: 'Roast Chicken', category_code: 'meal'
      create :transaction_categorization_case, words: 'Spaghetti', category_code: 'meal'
      create :transaction_categorization_case, words: 'Hamburger', category_code: 'meal'
      create :transaction_categorization_case, words: 'Baked Rice', category_code: 'meal'
      create :transaction_categorization_case, words: '三明治', category_code: 'meal'
      create :transaction_categorization_case, words: '牛排', category_code: 'meal'
      create :transaction_categorization_case, words: '豬排', category_code: 'meal'
      create :transaction_categorization_case, words: '烤雞', category_code: 'meal'
      create :transaction_categorization_case, words: '義大利麵', category_code: 'meal'
      create :transaction_categorization_case, words: '漢堡', category_code: 'meal'
      create :transaction_categorization_case, words: '焗烤飯', category_code: 'meal'
      create :transaction_categorization_case, words: 'Ice Tea', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Hot Tea', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Black Tea', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Orange Juice', category_code: 'drinks'
      create :transaction_categorization_case, words: 'Grape Juice', category_code: 'drinks'
      create :transaction_categorization_case, words: '紅茶', category_code: 'drinks'
      create :transaction_categorization_case, words: '綠茶', category_code: 'drinks'
      create :transaction_categorization_case, words: '珍珠奶茶', category_code: 'drinks'
      create :transaction_categorization_case, words: '柳橙汁', category_code: 'drinks'
      create :transaction_categorization_case, words: '葡萄汁', category_code: 'drinks'
      create :transaction_categorization_case, words: 'SNICKERS', category_code: 'snacks'
      create :transaction_categorization_case, words: 'Pringle\'s Newfangled Potato Chips', category_code: 'snacks'
      create :transaction_categorization_case, words: 'Doritos', category_code: 'snacks'
      create :transaction_categorization_case, words: '士力架 巧克力', category_code: 'snacks'
      create :transaction_categorization_case, words: '品客 洋芋片', category_code: 'snacks'
      create :transaction_categorization_case, words: '多力多滋', category_code: 'snacks'

      # User2 eats SNICKERS as meals and doesn't drink tea
      @user2 = create(:user)
      create :transaction_categorization_case, words: 'SNICKERS', category_code: 'meal', user: @user2
      create :transaction_categorization_case, words: 'SNICKERS', category_code: 'meal', user: @user2
      create :transaction_categorization_case, words: '士力架 巧克力', category_code: 'meal', user: @user2
      create :transaction_categorization_case, words: '士力架 巧克力', category_code: 'meal', user: @user2
      tcs = TransactionCategoryService.new(@user2)
      tcs.transaction_category_set = {
        food: {
          name: "Food",
          priority: 1,
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
            snacks: {
              name: "Snacks",
              priority: 9
            }
          }
        }
      }
    end

    let(:user2) { @user2 }

    it "categorize words generally" do
      tcs = TransactionCategoryService.new(user)

      expect(tcs.categorize('Tea')).to eq('drinks')
      expect(tcs.categorize('茶')).to eq('drinks')
      expect(tcs.categorize('烏龍茶')).to eq('drinks')
      expect(tcs.categorize('夕立汁')).to eq('drinks')
      expect(tcs.categorize('SNICKERS')).to eq('snacks')
      expect(tcs.categorize('巧克力')).to eq('snacks')
      expect(tcs.categorize('洋芋片')).to eq('snacks')
      expect(tcs.categorize('Nothing')).to eq('other')
    end

    it "categorize words customize" do
      tcs = TransactionCategoryService.new(user2)

      expect(tcs.categorize('Tea')).not_to eq('drinks')
      expect(tcs.categorize('茶')).not_to eq('drinks')
      expect(tcs.categorize('烏龍茶')).not_to eq('drinks')
      expect(tcs.categorize('夕立汁')).not_to eq('drinks')
      expect(tcs.categorize('SNICKERS')).to eq('meal')
      expect(tcs.categorize('巧克力')).to eq('meal')
      expect(tcs.categorize('洋芋片')).to eq('snacks')
      expect(tcs.categorize('Nothing')).to eq('other')
    end

    it "categorize words by time and location" do
      WebMock.allow_net_connect!

      tcs = TransactionCategoryService.new(user)
      expect(tcs.categorize('Sandwich', datetime: Time.new(2000, 1, 1, 8, 0, 0, 0))).to eq('breakfast')
      expect(tcs.categorize('Sandwich', datetime: Time.new(2000, 1, 1, 12, 0, 0, 0))).to eq('launch')
      expect(tcs.categorize('Sandwich', datetime: Time.new(2000, 1, 1, 0, 0, 0, 0))).to eq('supper')
      expect(tcs.categorize('Sandwich', datetime: Time.new(2000, 1, 1, 0, 0, 0, 0), latitude: 23.996917, longitude: 121.638565)).to eq('breakfast')
      expect(tcs.categorize('Sandwich', datetime: Time.new(2000, 1, 1, 4, 0, 0, 0), latitude: 23.996917, longitude: 121.638565)).to eq('launch')
      expect(tcs.categorize('牛排', datetime: Time.new(2000, 1, 1, 12, 0, 0, 0), latitude: 23.996917, longitude: 121.638565)).to eq('dinner')
    end
  end
end
