# Shared helper for documentation spec files
require 'spec_helper'
require 'musa-dsl'

# Shared aliases needed for RSpec lexical scoping in documentation specs
# Note: 'using' statements must be in each spec file due to lexical scope requirements
Scales = Musa::Scales::Scales unless defined?(Scales)
Neumalang = Musa::Neumalang::Neumalang unless defined?(Neumalang)
Decoders = Musa::Neumas::Decoders unless defined?(Decoders)
