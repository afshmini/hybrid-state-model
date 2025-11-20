# frozen_string_literal: true

module HybridStateModel
  module QueryMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def in_primary(*states)
        field = state_machine.primary_field
        where(field => states.map(&:to_sym))
      end

      def in_micro(*states)
        field = state_machine.micro_field
        where(field => states.map(&:to_sym))
      end

      def with_primary_and_micro(primary:, micro:)
        in_primary(primary).in_micro(micro)
      end

      def without_micro
        field = state_machine.micro_field
        where(field => nil)
      end

      def with_micro
        field = state_machine.micro_field
        where.not(field => nil)
      end
    end
  end
end

