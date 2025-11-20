# frozen_string_literal: true

module HybridStateModel
  class StateMachine
    attr_reader :model_class, :primary_field, :micro_field, :primary_states, :micro_states,
                :state_mappings, :callbacks, :auto_reset_micro

    def initialize(model_class)
      @model_class = model_class
      @primary_states = []
      @micro_states = []
      @state_mappings = {}
      @callbacks = {
        before_primary_transition: {},
        after_primary_transition: {},
        before_micro_transition: {},
        after_micro_transition: {}
      }
      @auto_reset_micro = false
    end

    def primary(field_name, states)
      @primary_field = field_name.to_sym
      @primary_states = states.map(&:to_sym)
    end

    def micro(field_name, states)
      @micro_field = field_name.to_sym
      @micro_states = states.map(&:to_sym)
    end

    def map(primary_state:, micro_states:)
      primary_key = primary_state.to_sym
      micro_list = Array(micro_states).map(&:to_sym)
      @state_mappings[primary_key] = micro_list
    end

    def before_primary_transition(states, &block)
      Array(states).each do |state|
        @callbacks[:before_primary_transition][state.to_sym] ||= []
        @callbacks[:before_primary_transition][state.to_sym] << block
      end
    end

    def after_primary_transition(states, &block)
      Array(states).each do |state|
        @callbacks[:after_primary_transition][state.to_sym] ||= []
        @callbacks[:after_primary_transition][state.to_sym] << block
      end
    end

    def before_micro_transition(states, &block)
      Array(states).each do |state|
        @callbacks[:before_micro_transition][state.to_sym] ||= []
        @callbacks[:before_micro_transition][state.to_sym] << block
      end
    end

    def after_micro_transition(states, &block)
      Array(states).each do |state|
        @callbacks[:after_micro_transition][state.to_sym] ||= []
        @callbacks[:after_micro_transition][state.to_sym] << block
      end
    end

    def when_primary_changes(reset_micro: false)
      @auto_reset_micro = reset_micro
    end

    def setup!
      raise Error, "Primary state field must be defined" unless @primary_field
      raise Error, "Micro state field must be defined" unless @micro_field
      raise Error, "Primary states must be defined" if @primary_states.empty?

      @model_class.include(Core)
      @model_class.include(TransitionMethods)
      @model_class.include(QueryMethods)
      @model_class.include(Metrics)

      setup_validations
      setup_callbacks
    end

    def valid_primary_state?(state)
      @primary_states.include?(state.to_sym)
    end

    def valid_micro_state?(micro_state, primary_state)
      return true if micro_state.nil?

      primary_key = primary_state.to_sym
      allowed_micros = @state_mappings[primary_key]

      return true if allowed_micros.nil? || allowed_micros.empty?

      allowed_micros.include?(micro_state.to_sym)
    end

    def can_transition_to_primary?(record, new_state)
      return false unless valid_primary_state?(new_state)

      # Check callbacks
      callbacks = @callbacks[:before_primary_transition][new_state.to_sym] || []
      callbacks.all? { |cb| record.instance_exec(&cb) != false }
    end

    def can_transition_to_micro?(record, new_micro_state)
      return false if new_micro_state.nil?

      current_primary = record.send(@primary_field)
      return false unless valid_micro_state?(new_micro_state, current_primary)

      # Check callbacks
      callbacks = @callbacks[:before_micro_transition][new_micro_state.to_sym] || []
      callbacks.all? { |cb| record.instance_exec(&cb) != false }
    end

    private

    def setup_validations
      @model_class.validate :validate_hybrid_state

      @model_class.define_method(:validate_hybrid_state) do
        current_primary = send(state_machine.primary_field)
        current_micro = send(state_machine.micro_field)

        unless state_machine.valid_primary_state?(current_primary)
          errors.add(state_machine.primary_field, "is not a valid primary state")
        end

        unless state_machine.valid_micro_state?(current_micro, current_primary)
          errors.add(state_machine.micro_field, "is not valid for primary state #{current_primary}")
        end
      end
    end

    def setup_callbacks
      @model_class.before_save :track_state_changes
      @model_class.after_save :record_state_metrics
    end
  end
end

