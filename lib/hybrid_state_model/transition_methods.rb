# frozen_string_literal: true

module HybridStateModel
  module TransitionMethods
    def promote!(new_primary_state, options = {})
      new_state = new_primary_state.to_sym

      unless can_transition_to_primary?(new_state)
        raise InvalidTransitionError, "Cannot transition to primary state: #{new_state}"
      end

      old_primary = primary_state_value
      old_micro = micro_state_value

      # Run before callbacks
      run_callbacks(:before_primary_transition, new_state)

      # Update primary state
      send("#{primary_state}=", new_state)

      # Reset micro state if configured or if new state doesn't allow current micro
      if state_machine.auto_reset_micro || !valid_micro_state?(old_micro, new_state)
        send("#{micro_state}=", nil) unless options[:keep_micro]
      end

      # Save if not already in a transaction
      save! unless options[:skip_save]

      # Run after callbacks
      run_callbacks(:after_primary_transition, new_state)

      self
    end

    def advance!(new_micro_state, options = {})
      new_state = new_micro_state.to_sym

      unless can_transition_to_micro?(new_state)
        raise InvalidTransitionError, "Cannot transition to micro state: #{new_state}"
      end

      # Run before callbacks
      run_callbacks(:before_micro_transition, new_state)

      # Update micro state
      send("#{micro_state}=", new_state)

      # Save if not already in a transaction
      save! unless options[:skip_save]

      # Run after callbacks
      run_callbacks(:after_micro_transition, new_state)

      self
    end

    def reset_micro!(options = {})
      send("#{micro_state}=", nil)
      save! unless options[:skip_save]
      self
    end

    def transition!(primary: nil, micro: nil, options = {})
      if primary && primary != primary_state_value
        promote!(primary, options.merge(skip_save: true))
      end

      if micro && micro != micro_state_value
        advance!(micro, options)
      elsif primary && !micro
        save! unless options[:skip_save]
      end

      self
    end

    private

    def run_callbacks(callback_type, state)
      callbacks = state_machine.callbacks[callback_type][state] || []
      callbacks.each { |cb| instance_exec(&cb) }
    end
  end
end

