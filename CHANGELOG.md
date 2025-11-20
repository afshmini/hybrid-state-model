# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-01

### Added
- Initial release of hybrid-state-model
- Two-layer state system (primary state + micro state)
- DSL for defining states and mappings
- Transition methods: `promote!`, `advance!`, `reset_micro!`, `transition!`
- Query scopes: `in_primary`, `in_micro`, `with_primary_and_micro`, `with_micro`, `without_micro`
- Automatic state validation
- Callbacks: `before_primary_transition`, `after_primary_transition`, `before_micro_transition`, `after_micro_transition`
- Optional metrics tracking for time spent in states
- Support for auto-resetting micro state when primary state changes

