module Musa
  # MusicXML generation system.
  #
  # This module provides a comprehensive DSL for generating MusicXML 3.0 files
  # programmatically. It uses a builder pattern with a flexible API that supports
  # both constructor-based and DSL-style notation creation.
  #
  # ## Architecture
  #
  # The MusicXML builder system is organized hierarchically:
  #
  #     ScorePartwise (root)
  #       ├── Metadata (work, movement, creators, rights)
  #       ├── PartGroup (grouping)
  #       └── Part
  #           └── Measure
  #               ├── Attributes (key, time, clef, divisions)
  #               ├── Direction (dynamics, tempo, expressions)
  #               ├── PitchedNote / Rest / UnpitchedNote
  #               └── Backup / Forward (timeline navigation)
  #
  # ## DSL Features
  #
  # The builder provides two equivalent ways to create scores:
  #
  # 1. **Constructor + add methods**: Imperative style
  # 2. **DSL blocks**: Declarative style with `with` blocks
  #
  # Both styles leverage `AttributeBuilder` and `With` mixins from core-ext.
  #
  # ## Use Cases
  #
  # - Algorithmic composition with MusicXML export
  # - Score generation from Musa DSL performances
  # - Converting MIDI recordings to notation
  # - Creating notation examples programmatically
  #
  # @example Simple score with DSL style
  #   score = Musa::MusicXML::Builder::ScorePartwise.new do
  #     work_title "My Composition"
  #     creators composer: "Composer Name"
  #
  #     part :p1, name: "Piano" do
  #       measure do
  #         attributes do
  #           divisions 2
  #           key fifths: 0  # C major
  #           time beats: 4, beat_type: 4
  #           clef sign: 'G', line: 2
  #         end
  #
  #         pitch 'C', octave: 4, duration: 2, type: 'quarter'
  #         pitch 'D', octave: 4, duration: 2, type: 'quarter'
  #         pitch 'E', octave: 4, duration: 2, type: 'quarter'
  #         pitch 'F', octave: 4, duration: 2, type: 'quarter'
  #       end
  #     end
  #   end
  #
  #   File.write('output.xml', score.to_xml.string)
  #
  # @example Constructor + add methods style
  #   score = Musa::MusicXML::Builder::ScorePartwise.new
  #   score.work_title = "My Composition"
  #   score.add_creator "composer", "Composer Name"
  #
  #   part = score.add_part :p1, name: "Piano"
  #   measure = part.add_measure divisions: 2
  #   measure.attributes.last.add_key fifths: 0
  #   measure.attributes.last.add_time beats: 4, beat_type: 4
  #   measure.attributes.last.add_clef sign: 'G', line: 2
  #
  #   measure.add_pitch step: 'C', octave: 4, duration: 2, type: 'quarter'
  #
  #   File.write('output.xml', score.to_xml.string)
  #
  # @see Builder Main builder namespace
  # @see Builder::ScorePartwise Entry point for score creation
  module MusicXML
    # Builder classes for MusicXML generation.
    #
    # Contains all the builder classes that construct MusicXML elements.
    # The main entry point is {ScorePartwise}.
    #
    # @see ScorePartwise Main score builder
    module Builder
      # Internal implementation classes for MusicXML builder.
      #
      # This module contains the actual implementation classes used by the builder.
      # Users should access these through the main `Musa::MusicXML::Builder` namespace.
      #
      # @api private
      module Internal
        # Helper modules and methods for MusicXML generation.
        #
        # Provides shared functionality for XML serialization, element construction,
        # and value formatting across all builder classes.
        module Helper
          # Mixin for classes not yet implemented.
          #
          # Used as a placeholder for MusicXML elements that are planned but not
          # yet implemented. Raises `NotImplementedError` when attempting to use.
          #
          # @api private
          module NotImplemented
            # Placeholder initializer accepting any parameters.
            #
            # @param _args [Hash] ignored keyword arguments
            def initialize(**_args); end

            # Raises error indicating the class is not implemented.
            #
            # @param io [IO, nil] ignored
            # @param indent [Integer, nil] ignored
            # @raise [NotImplementedError] always raised with helpful message
            def to_xml(io = nil, indent: nil)
              raise NotImplementedError, "#{self.class} not yet implemented. Ask Javier do his work!"
            end
          end

          # Mixin for XML serialization capability.
          #
          # Provides the public `to_xml` interface that handles IO and indentation
          # setup, delegating to the private `_to_xml` method for actual XML generation.
          #
          # ## Usage
          #
          # Classes including this module must implement `_to_xml(io, indent:, tabs:)`.
          #
          # @example Including in a class
          #   class MyElement
          #     include Musa::MusicXML::Builder::Internal::Helper::ToXML
          #
          #     private
          #
          #     def _to_xml(io, indent:, tabs:)
          #       io.puts "#{tabs}<my-element />"
          #     end
          #   end
          #
          #   element = MyElement.new
          #   element.to_xml  # => StringIO with XML content
          module ToXML
            # Converts the object to MusicXML format.
            #
            # This method sets up the IO stream and indentation, then delegates to
            # the private `_to_xml` method for actual XML generation.
            #
            # @param io [IO, StringIO, nil] output stream (creates StringIO if nil)
            # @param indent [Integer, nil] indentation level (default: 0)
            # @return [IO, StringIO] the io parameter, containing the XML output
            #
            # @example Writing to file
            #   File.open('output.xml', 'w') do |f|
            #     element.to_xml(f)
            #   end
            #
            # @example Getting XML as string
            #   xml_string = element.to_xml.string
            def to_xml(io = nil, indent: nil)
              io ||= StringIO.new
              indent ||= 0

              tabs = "\t" * indent

              _to_xml(io, indent: indent, tabs: tabs)

              io
            end

            private

            # Abstract method for XML generation.
            #
            # Subclasses must implement this method to generate their XML content.
            #
            # @param io [IO] output stream to write XML to
            # @param indent [Integer] current indentation level
            # @param tabs [String] precomputed tab string for current indent
            # @return [void]
            #
            # @api private
            def _to_xml(io, indent:, tabs:); end
          end

          # Mixin for XML header serialization (used in part-list).
          #
          # Similar to {ToXML}, but for elements that appear in the `<part-list>`
          # section of MusicXML (parts and part groups).
          #
          # Classes including this module must implement `_header_to_xml(io, indent:, tabs:)`.
          module HeaderToXML
            # Converts the object's header representation to MusicXML.
            #
            # Used for elements that appear in the `<part-list>` section, such as
            # `<score-part>` and `<part-group>` declarations.
            #
            # @param io [IO, StringIO, nil] output stream (creates StringIO if nil)
            # @param indent [Integer, nil] indentation level (default: 0)
            # @return [IO, StringIO] the io parameter, containing the XML output
            def header_to_xml(io = nil, indent: nil)
              io ||= StringIO.new
              indent ||= 0

              tabs = "\t" * indent

              _header_to_xml(io, indent: indent, tabs: tabs)

              io
            end

            private

            # Abstract method for header XML generation.
            #
            # Subclasses must implement this method to generate their header XML.
            #
            # @param io [IO] output stream to write XML to
            # @param indent [Integer] current indentation level
            # @param tabs [String] precomputed tab string for current indent
            # @return [void]
            #
            # @api private
            def _header_to_xml(io, indent:, tabs:); end
          end

          private

          # Creates class instance from Hash or returns existing instance.
          #
          # This helper method provides flexible parameter handling, allowing
          # methods to accept either a fully-constructed instance or a hash of
          # constructor parameters.
          #
          # @param klass [Class] expected class type
          # @param hash_or_class_instance [klass, Hash, nil] value to process
          # @return [klass, nil] instance of klass, or nil
          #
          # @raise [ArgumentError] if value is not klass, Hash, or nil
          #
          # @example Flexible parameter acceptance
          #   # Method can accept either:
          #   time_modification: { actual_notes: 3, normal_notes: 2 }
          #   # or:
          #   time_modification: TimeModification.new(actual_notes: 3, normal_notes: 2)
          #
          # @api private
          def make_instance_if_needed(klass, hash_or_class_instance)
            case hash_or_class_instance
            when klass
              hash_or_class_instance
            when Hash
              klass.new **hash_or_class_instance
            when nil
              nil
            else
              raise ArgumentError, "#{hash_or_class_instance} is not a Hash, nor a #{klass.name} nor nil"
            end
          end

          # Converts value to XML attribute string with boolean support.
          #
          # Handles three types of values:
          # - **String/Numeric**: Outputs as attribute value
          # - **true**: Outputs specified true_value (if provided)
          # - **false**: Outputs specified false_value (if provided)
          # - **Other**: Returns empty string (omits attribute)
          #
          # @param value [Object] value to convert
          # @param attribute [String] attribute name
          # @param true_value [String, nil] value to use for `true`
          # @param false_value [String, nil] value to use for `false`
          # @return [String] formatted attribute string or empty string
          #
          # @example String value
          #   decode_bool_or_string_attribute('above', 'placement')
          #   # => ' placement="above"'
          #
          # @example Boolean with mappings
          #   decode_bool_or_string_attribute(true, 'bracket', 'yes', 'no')
          #   # => ' bracket="yes"'
          #
          # @example Nil value
          #   decode_bool_or_string_attribute(nil, 'placement')
          #   # => ''
          #
          # @api private
          def decode_bool_or_string_attribute(value, attribute, true_value = nil, false_value = nil)
            if value.is_a?(String) || value.is_a?(Numeric)
              " #{attribute}=\"#{value}\""
            elsif value.is_a?(TrueClass) && true_value
              " #{attribute}=\"#{true_value}\""
            elsif value.is_a?(FalseClass) && false_value
              " #{attribute}=\"#{false_value}\""
            else
              ''
            end
          end

          # Converts value to XML element content with boolean support.
          #
          # Similar to {#decode_bool_or_string_attribute} but for element content
          # rather than attributes.
          #
          # @param value [Object] value to convert
          # @param true_value [String, nil] value to use for `true`
          # @param false_value [String, nil] value to use for `false`
          # @return [String] formatted content string or empty string
          #
          # @example
          #   decode_bool_or_string_value(true, 'yes', 'no')  # => 'yes'
          #   decode_bool_or_string_value('dashed')          # => 'dashed'
          #
          # @api private
          def decode_bool_or_string_value(value, true_value = nil, false_value = nil)
            if value.is_a?(String) || value.is_a?(Numeric)
              value
            elsif value.is_a?(TrueClass) && true_value
              true_value
            elsif value.is_a?(FalseClass) && false_value
              false_value
            else
              ''
            end
          end
        end
      end
    end
  end
end