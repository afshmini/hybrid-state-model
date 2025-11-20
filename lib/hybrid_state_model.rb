# frozen_string_literal: true

require_relative "hybrid_state_model/version"
require_relative "hybrid_state_model/core"
require_relative "hybrid_state_model/state_machine"
require_relative "hybrid_state_model/query_methods"
require_relative "hybrid_state_model/metrics"
require_relative "hybrid_state_model/transition_methods"

module HybridStateModel
  class Error < StandardError; end
  class InvalidTransitionError < Error; end
  class InvalidStateError < Error; end
  class InvalidMicroStateError < Error; end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def hybrid_state(&block)
      @state_machine = StateMachine.new(self)
      @state_machine.instance_eval(&block)
      @state_machine.setup!
    end

    def state_machine
      @state_machine
    end
  end
end

