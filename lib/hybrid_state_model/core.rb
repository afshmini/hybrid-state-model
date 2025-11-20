# frozen_string_literal: true

module HybridStateModel
  module Core
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def hybrid_state_model?
        true
      end
    end

    def primary_state
      state_machine.primary_field
    end

    def micro_state
      state_machine.micro_field
    end

    def state_machine
      self.class.state_machine
    end

    def primary_state_value
      send(primary_state)
    end

    def micro_state_value
      send(micro_state)
    end

    def valid_primary_state?(state)
      state_machine.valid_primary_state?(state)
    end

    def valid_micro_state?(state)
      state_machine.valid_micro_state?(state, primary_state_value)
    end

    def can_transition_to_primary?(new_state)
      state_machine.can_transition_to_primary?(self, new_state)
    end

    def can_transition_to_micro?(new_micro_state)
      state_machine.can_transition_to_micro?(self, new_micro_state)
    end
  end
end

