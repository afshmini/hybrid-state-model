# frozen_string_literal: true

require "bundler/setup"
require "hybrid_state_model"
require "active_record"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Setup database
  config.before(:suite) do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: ":memory:"
    )

    ActiveRecord::Schema.define do
      create_table :orders do |t|
        t.string :status
        t.string :sub_status
        t.text :state_metrics
        t.boolean :paid, default: false
        t.timestamps
      end
    end
  end

  config.after(:each) do
    Order.delete_all
  end
end

