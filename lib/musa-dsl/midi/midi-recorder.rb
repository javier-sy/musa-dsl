require 'nibbler'

module Musa
	class MIDIRecorder
		def initialize sequencer
			@sequencer = sequencer
			@nibbler = Nibbler.new

			clear
		end

		def clear
			@messages = []
		end

		def record midi_bytes
			m = @nibbler.parse midi_bytes
			m = [m] unless m.is_a? Array

			m.each do |mm|
				@messages << Message.new(@sequencer.position, mm)
			end
		end

		def raw
			@messages
		end

		def transcription
			note_on = {}
			last_note = {}

			notes = []

			@messages.each do |m|

				mm = m.message

				case 
				when mm.is_a?(MIDIMessage::NoteOn)

					if last_note[mm.channel]
						notes << { position: last_note[mm.channel], channel: mm.channel, pitch: :silence, duration: m.position - last_note[mm.channel] }
						last_note.delete mm.channel
					end

					note = { position: m.position, channel: mm.channel, pitch: mm.note, velocity: mm.velocity }

					note_on[mm.channel] ||= {}
					note_on[mm.channel][mm.note] = note

					notes << note

				when mm.is_a?(MIDIMessage::NoteOff)

					note_on[mm.channel] ||= {}

					note = note_on[mm.channel][mm.note]

					if note
						note_on[mm.channel].delete mm.note

						note[:duration] = m.position - note[:position]
						note[:velocity_off] = mm.velocity
					end

					last_note[mm.channel] = m.position
				else
					# ignore other midi messages
				end
			end

			notes
		end
	
		class Message
			attr_accessor :position, :message

			def initialize position, message
				@position = position
				@message = message
			end
		end

		private_constant :Message
	end
end