# frozen_string_literal: true

# Example: Order model with hybrid state
#
# This example demonstrates how to use hybrid-state-model
# for an e-commerce order workflow

require "active_record"
require_relative "../lib/hybrid_state_model"

# Setup database (in a real app, this would be a migration)
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

class Order < ActiveRecord::Base
  include HybridStateModel

  hybrid_state do
    # Define primary state (high-level lifecycle)
    primary :status, %i[pending processing shipped delivered returned]

    # Define micro state (steps within primary state)
    micro :sub_status, %i[
      awaiting_payment
      fraud_check_passed
      fraud_check_failed
      ready_to_pack
      packing
      assigning_carrier
      waiting_for_pickup
      in_transit
      out_for_delivery
      inspection
      return_processing
      return_complete
    ]

    # Map which micro-states are allowed for each primary state
    map status: :pending, sub_status: %i[awaiting_payment]
    map status: :processing, sub_status: %i[fraud_check_passed fraud_check_failed ready_to_pack packing assigning_carrier]
    map status: :shipped, sub_status: %i[waiting_for_pickup in_transit out_for_delivery]
    map status: :returned, sub_status: %i[inspection return_processing return_complete]

    # Automatically reset micro state when primary state changes
    when_primary_changes reset_micro: true

    # Callbacks
    before_primary_transition :shipped do
      raise "Cannot ship unpaid order" unless paid?
    end

    after_primary_transition :delivered do
      puts "Order #{id} has been delivered!"
    end
  end
end

# Example usage
if __FILE__ == $PROGRAM_NAME
  puts "=== Hybrid State Model Example ===\n\n"

  # Create an order
  order = Order.create!(status: :pending, sub_status: :awaiting_payment, paid: false)
  puts "1. Created order: #{order.status} / #{order.sub_status}"

  # Mark as paid and move to processing
  order.update!(paid: true)
  order.promote!(:processing)
  puts "2. Promoted to: #{order.status} / #{order.sub_status}"

  # Advance through micro states
  order.advance!(:ready_to_pack)
  puts "3. Advanced to: #{order.status} / #{order.sub_status}"

  order.advance!(:packing)
  puts "4. Advanced to: #{order.status} / #{order.sub_status}"

  # Transition both at once
  order.transition!(primary: :shipped, micro: :waiting_for_pickup)
  puts "5. Transitioned to: #{order.status} / #{order.sub_status}"

  # Continue through shipping micro states
  order.advance!(:in_transit)
  puts "6. Advanced to: #{order.status} / #{order.sub_status}"

  order.advance!(:out_for_delivery)
  puts "7. Advanced to: #{order.status} / #{order.sub_status}"

  # Final state
  order.promote!(:delivered)
  puts "8. Final state: #{order.status} / #{order.sub_status}"

  # Query examples
  puts "\n=== Query Examples ==="
  puts "Orders in 'shipped' state: #{Order.in_primary(:shipped).count}"
  puts "Orders with micro state 'in_transit': #{Order.in_micro(:in_transit).count}"

  puts "\n=== Example Complete ==="
end

