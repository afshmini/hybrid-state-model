# Hybrid State Model

A revolutionary two-layer hierarchical state system for Ruby models. Perfect for complex workflows that are too complex for flat state machines but don't need full orchestration engines.

## 🌟 The Big Idea

**hybrid-state-model** introduces a two-layer state system:

- **Primary State** — high-level lifecycle (e.g., `pending`, `active`, `shipped`, `delivered`)
- **Secondary Micro-State** — small step within the primary state (e.g., `verifying_email`, `awaiting_payment`, `in_transit`, `out_for_delivery`)

This creates a simple but powerful hierarchical state system that reduces complexity instead of adding it.

## ✨ Features

- 🎯 **Two-layer state system** — Primary states with nested micro-states
- 🔒 **Automatic constraints** — Micro-states are validated against their primary state
- 🚀 **Flexible transitions** — `promote!`, `advance!`, `reset_micro!`, and `transition!`
- 🔍 **Querying capabilities** — `in_primary`, `in_micro`, `with_primary_and_micro` scopes
- 📊 **Metrics tracking** — Track time spent in each state (optional)
- 🎛️ **Callbacks** — `before_primary_transition`, `after_primary_transition`, etc.
- ✅ **ActiveRecord integration** — Works seamlessly with Rails models

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'hybrid-state-model'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install hybrid-state-model
```

## 🚀 Quick Start

### 1. Create your migration

```ruby
class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.string :status          # Primary state
      t.string :sub_status      # Micro state
      t.text :state_metrics     # Optional: for metrics tracking
      
      t.timestamps
    end
  end
end
```

### 2. Define your model

```ruby
class Order < ActiveRecord::Base
  include HybridStateModel

  hybrid_state do
    # Define primary state field and possible values
    primary :status, %i[pending processing shipped delivered returned]

    # Define micro state field and possible values
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

    # Optional: Reset micro state when primary state changes
    when_primary_changes reset_micro: true

    # Optional: Callbacks
    before_primary_transition :shipped do
      raise "Cannot ship without payment" unless paid?
    end

    after_primary_transition :delivered do
      send_delivery_confirmation_email
    end
  end
end
```

### 3. Use it!

```ruby
# Create an order
order = Order.create!(status: :pending, sub_status: :awaiting_payment)

# Promote to primary state (moves to next major state)
order.promote!(:processing)
# => status: :processing, sub_status: nil (reset because of when_primary_changes)

# Advance micro state (moves within current primary state)
order.advance!(:ready_to_pack)
# => status: :processing, sub_status: :ready_to_pack

# Transition both at once
order.transition!(primary: :shipped, micro: :waiting_for_pickup)
# => status: :shipped, sub_status: :waiting_for_pickup

# Advance through micro states
order.advance!(:in_transit)
order.advance!(:out_for_delivery)

# Promote to final state
order.promote!(:delivered)

# Querying
Order.in_primary(:shipped)
Order.in_micro(:in_transit)
Order.with_primary_and_micro(primary: :shipped, micro: :out_for_delivery)
Order.with_micro  # Orders that have a micro state
Order.without_micro  # Orders without a micro state

# Validation
order.status = :delivered
order.sub_status = :assigning_carrier  # ❌ Invalid! Will fail validation
```

## 📚 API Reference

### DSL Methods

#### `primary(field_name, states)`
Defines the primary state field and its possible values.

```ruby
primary :status, %i[pending active inactive]
```

#### `micro(field_name, states)`
Defines the micro state field and its possible values.

```ruby
micro :sub_status, %i[verifying_email awaiting_approval]
```

#### `map(primary_state:, micro_states:)`
Maps which micro-states are allowed for a specific primary state.

```ruby
map status: :active, sub_status: %i[verifying_email awaiting_approval]
```

#### `when_primary_changes(reset_micro: true)`
Automatically resets the micro state when the primary state changes.

#### `before_primary_transition(states, &block)`
Runs a callback before transitioning to the specified primary state(s).

```ruby
before_primary_transition :shipped do
  validate_shipping_address
end
```

#### `after_primary_transition(states, &block)`
Runs a callback after transitioning to the specified primary state(s).

#### `before_micro_transition(states, &block)`
Runs a callback before transitioning to the specified micro state(s).

#### `after_micro_transition(states, &block)`
Runs a callback after transitioning to the specified micro state(s).

### Instance Methods

#### `promote!(new_primary_state, options = {})`
Transitions to a new primary state. Automatically resets micro state if configured.

```ruby
order.promote!(:shipped)
order.promote!(:delivered, skip_save: true)  # Don't save immediately
```

#### `advance!(new_micro_state, options = {})`
Transitions to a new micro state within the current primary state.

```ruby
order.advance!(:in_transit)
```

#### `reset_micro!(options = {})`
Resets the micro state to `nil`.

```ruby
order.reset_micro!
```

#### `transition!(primary:, micro:, options = {})`
Transitions both primary and micro states at once.

```ruby
order.transition!(primary: :shipped, micro: :waiting_for_pickup)
```

#### `can_transition_to_primary?(state)`
Checks if the record can transition to the specified primary state.

#### `can_transition_to_micro?(state)`
Checks if the record can transition to the specified micro state.

### Query Scopes

#### `in_primary(*states)`
Finds records with the specified primary state(s).

```ruby
Order.in_primary(:shipped, :delivered)
```

#### `in_micro(*states)`
Finds records with the specified micro state(s).

```ruby
Order.in_micro(:in_transit, :out_for_delivery)
```

#### `with_primary_and_micro(primary:, micro:)`
Finds records with both the specified primary and micro states.

```ruby
Order.with_primary_and_micro(primary: :shipped, micro: :in_transit)
```

#### `with_micro`
Finds records that have a micro state set.

#### `without_micro`
Finds records that don't have a micro state set.

## 📊 Metrics Tracking

If you add a `state_metrics` text/json column to your table, the gem will automatically track time spent in each state:

```ruby
# Migration
add_column :orders, :state_metrics, :text

# Usage
order.state_metrics
# => {
#   "pending" => {"entered_at" => "...", "duration" => 120.5},
#   "processing" => {"entered_at" => "...", "duration" => 300.0},
#   "processing:ready_to_pack" => {"entered_at" => "...", "duration" => 60.0}
# }

order.time_in_primary_state(:processing)
# => 300.0 (seconds)

order.current_state_duration
# => 45.2 (seconds in current state)
```

## 🎯 Use Cases

### Logistics & Shipping
```ruby
primary :status, %i[pending processing shipped delivered]
micro :sub_status, %i[ready_to_pack packing waiting_for_pickup in_transit out_for_delivery]
```

### Payment & Billing
```ruby
primary :status, %i[active suspended canceled]
micro :sub_status, %i[verifying_card awaiting_payment retrying_charge]
```

### User Onboarding
```ruby
primary :status, %i[active pending]
micro :sub_status, %i[verifying_email uploading_documents awaiting_approval]
```

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/afshmini/hybrid-state-model.

## 📝 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

