Dir[Rails.root.join("app/synchronizers/**/*.rb")].each { |f| load f }
