# frozen_string_literal: true

require "spec_helper"

class Order < ActiveRecord::Base
  include HybridStateModel

  hybrid_state do
    primary :status, %i[pending processing shipped delivered returned]
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

    map status: :pending, sub_status: %i[awaiting_payment]
    map status: :processing, sub_status: %i[fraud_check_passed fraud_check_failed ready_to_pack packing assigning_carrier]
    map status: :shipped, sub_status: %i[waiting_for_pickup in_transit out_for_delivery]
    map status: :returned, sub_status: %i[inspection return_processing return_complete]

    when_primary_changes reset_micro: true
  end
end

RSpec.describe HybridStateModel do
  describe "basic functionality" do
    it "allows setting primary and micro states" do
      order = Order.create!(status: :pending, sub_status: :awaiting_payment)
      expect(order.status).to eq("pending")
      expect(order.sub_status).to eq("awaiting_payment")
    end

    it "validates micro state against primary state" do
      order = Order.new(status: :pending, sub_status: :in_transit)
      expect(order).not_to be_valid
      expect(order.errors[:sub_status]).to be_present
    end

    it "allows nil micro state" do
      order = Order.new(status: :pending, sub_status: nil)
      expect(order).to be_valid
    end
  end

  describe "#promote!" do
    it "transitions to new primary state" do
      order = Order.create!(status: :pending, sub_status: :awaiting_payment)
      order.promote!(:processing)
      expect(order.status).to eq("processing")
      expect(order.sub_status).to be_nil
    end

    it "raises error for invalid transition" do
      order = Order.create!(status: :pending)
      expect { order.promote!(:invalid_state) }.to raise_error(HybridStateModel::InvalidTransitionError)
    end
  end

  describe "#advance!" do
    it "transitions to new micro state" do
      order = Order.create!(status: :processing)
      order.advance!(:ready_to_pack)
      expect(order.sub_status).to eq("ready_to_pack")
    end

    it "raises error for invalid micro state" do
      order = Order.create!(status: :pending)
      expect { order.advance!(:in_transit) }.to raise_error(HybridStateModel::InvalidTransitionError)
    end
  end

  describe "#transition!" do
    it "transitions both primary and micro states" do
      order = Order.create!(status: :pending)
      order.transition!(primary: :shipped, micro: :waiting_for_pickup)
      expect(order.status).to eq("shipped")
      expect(order.sub_status).to eq("waiting_for_pickup")
    end
  end

  describe "query scopes" do
    before do
      Order.create!(status: :pending, sub_status: :awaiting_payment)
      Order.create!(status: :processing, sub_status: :ready_to_pack)
      Order.create!(status: :shipped, sub_status: :in_transit)
      Order.create!(status: :shipped, sub_status: :out_for_delivery)
    end

    it "finds by primary state" do
      expect(Order.in_primary(:shipped).count).to eq(2)
    end

    it "finds by micro state" do
      expect(Order.in_micro(:in_transit).count).to eq(1)
    end

    it "finds by primary and micro state" do
      expect(Order.with_primary_and_micro(primary: :shipped, micro: :in_transit).count).to eq(1)
    end

    it "finds records with micro state" do
      expect(Order.with_micro.count).to eq(4)
    end
  end

  describe "callbacks" do
    it "runs before_primary_transition callbacks" do
      order = Order.create!(status: :pending)
      
      Order.state_machine.before_primary_transition(:shipped) do
        @callback_called = true
      end

      order.promote!(:shipped)
      expect(order.instance_variable_get(:@callback_called)).to be true
    end
  end
end

