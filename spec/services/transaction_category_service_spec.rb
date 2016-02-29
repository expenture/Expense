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
          name: "food",
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

  describe ".transaction_category_set" do
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
end
