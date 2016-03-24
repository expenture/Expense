Dir[Rails.root.join("app/synchronizers/**/*.rb")].each { |f| load f } if Rails.env.production?
