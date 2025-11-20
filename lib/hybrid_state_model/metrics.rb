# frozen_string_literal: true

require "json"

module HybridStateModel
  module Metrics
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_state_metrics?
        column_names.include?("state_metrics")
      end
    end

    def track_state_changes
      return unless persisted?

      @state_changed = primary_state_changed? || micro_state_changed?
      @old_primary = primary_state_was if primary_state_changed?
      @old_micro = micro_state_was if micro_state_changed?
    end

    def record_state_metrics
      return unless @state_changed

      metrics = state_metrics_hash
      current_time = Time.now

      # Record exit time for old state
      if @old_primary
        metrics[@old_primary.to_s] ||= {}
        metrics[@old_primary.to_s]["exited_at"] ||= current_time.iso8601
        metrics[@old_primary.to_s]["duration"] ||= 0
        if metrics[@old_primary.to_s]["entered_at"]
          duration = current_time - Time.parse(metrics[@old_primary.to_s]["entered_at"])
          metrics[@old_primary.to_s]["duration"] += duration
        end
      end

      # Record entry time for new state
      new_primary = primary_state_value
      if new_primary
        metrics[new_primary.to_s] ||= {}
        metrics[new_primary.to_s]["entered_at"] = current_time.iso8601
        metrics[new_primary.to_s]["duration"] ||= 0
      end

      # Record micro state metrics
      if @old_micro && @old_primary
        micro_key = "#{@old_primary}:#{@old_micro}"
        metrics[micro_key] ||= {}
        metrics[micro_key]["exited_at"] ||= current_time.iso8601
        if metrics[micro_key]["entered_at"]
          duration = current_time - Time.parse(metrics[micro_key]["entered_at"])
          metrics[micro_key]["duration"] ||= 0
          metrics[micro_key]["duration"] += duration
        end
      end

      if micro_state_value && new_primary
        micro_key = "#{new_primary}:#{micro_state_value}"
        metrics[micro_key] ||= {}
        metrics[micro_key]["entered_at"] = current_time.iso8601
        metrics[micro_key]["duration"] ||= 0
      end

      # Store metrics if column exists
      if self.class.has_state_metrics?
        self.state_metrics = metrics.to_json
      end

      @state_changed = false
    end

    def state_metrics
      return {} unless self.class.has_state_metrics?

      json = read_attribute(:state_metrics)
      return {} if json.blank?

      JSON.parse(json)
    rescue JSON::ParserError
      {}
    end

    def state_metrics_hash
      state_metrics
    end

    def time_in_primary_state(state = nil)
      state ||= primary_state_value
      metrics = state_metrics_hash[state.to_s] || {}
      metrics["duration"] || 0
    end

    def time_in_micro_state(primary_state, micro_state)
      key = "#{primary_state}:#{micro_state}"
      metrics = state_metrics_hash[key] || {}
      metrics["duration"] || 0
    end

    def current_state_duration
      return 0 unless persisted?

      current_primary = primary_state_value
      return 0 unless current_primary

      metrics = state_metrics_hash[current_primary.to_s] || {}
      entered_at = metrics["entered_at"]

      return 0 unless entered_at

      base_duration = metrics["duration"] || 0
      time_since_entry = Time.now - Time.parse(entered_at)
      base_duration + time_since_entry
    end

    private

    def primary_state_changed?
      send("#{primary_state}_changed?")
    end

    def micro_state_changed?
      send("#{micro_state}_changed?")
    end

    def primary_state_was
      send("#{primary_state}_was")
    end

    def micro_state_was
      send("#{micro_state}_was")
    end
  end
end

