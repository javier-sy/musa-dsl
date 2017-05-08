module Musa
	class MIDIVoices

		attr_accessor :log

		def initialize(sequencer:, output:, channels:, log: false)
			@sequencer = sequencer
			@output = output
			@channels = channels
			@do_log = log

			reset
		end

		def reset
			@voices = @channels.collect { |channel| MIDIVoice.new sequencer: @sequencer, output: @output, channel: channel, log: @do_log }
		end

		def voice(index)
			@voices[index]
		end

		def fast_forward=(enabled)
			@voices.apply :fast_forward=, enabled
		end
	end

	private

	class MIDIVoice

		attr_accessor :name, :do_log
		attr_reader :sequencer, :output, :channel, :used_pitches, :tick_duration

		def initialize(sequencer:, output:, channel:, name: nil, log: false)
			@sequencer = sequencer
			@output = output
			@channel = channel
			@name = name
			@do_log = log

			@tick_duration = Rational(1, @sequencer.ticks_per_bar)

			@used_pitches = []
			
			(0..127).each do |pitch|
				@used_pitches[pitch] = { counter: 0, velocity: 0 }
			end

			self
		end

		def fast_forward=(enabled)
			if @fast_forward && !enabled
				(0..127).each do |pitch|
					@output.puts MIDIMessage::NoteOn @channel, pitch, @used_pitches[pitch][:velocity] if @used_pitches[pitch][:counter] > 0
				end
			end

			@fast_forward = enabled
		end

		def fast_forward?
			@fast_forward
		end

		def note(pitchvalue = nil, pitch: nil, velocity: 63, duration: nil, velocity_off: 63)
			pitch ||= pitchvalue
			NoteControl.new self, pitch: pitch, velocity: velocity, duration: duration, velocity_off: velocity_off
		end

		def note_off(pitchvalue = nil, pitch: nil, velocity_off: 63)
			pitch ||= pitchvalue
			NoteControl.new(self, pitch: pitch, velocity_off: velocity, play: false).note_off
			nil
		end

		def log(msg)
			@sequencer.log "voice #{name}: #{msg}" if @do_log
		end

	 	def to_s
	 		"voice #{@name} output: #{@output} channel: #{@channel}"
	 	end

	 	private

		class NoteControl
			
			def initialize(voice, pitch:, velocity: nil, duration: nil, velocity_off: nil, play: true)

				raise ArgumentError, "MIDIVoice: note duration should be nil or Numeric: #{duration} (#{duration.class})" unless duration.nil? || duration.is_a?(Numeric)

				@voice = voice

				@pitch = Tool::explode_ranges_on_array(Tool::grant_array(pitch))
				@velocity = Tool::explode_ranges_on_array(Tool::grant_array(velocity))
				@velocity_off = Tool::explode_ranges_on_array(Tool::grant_array(velocity_off))

				@do_on_stop = []
				@do_after = []

				if play
					@pitch.each_index do |i|
						pitch = @pitch[i]
						velocity = @velocity[i % @velocity.size]
						velocity_off = @velocity_off[i % @velocity_off.size]

						if !silence?(pitch)
							@voice.used_pitches[pitch][:counter] += 1
							@voice.used_pitches[pitch][:velocity] = velocity

							msg = MIDIMessage::NoteOn.new(@voice.channel, pitch, velocity)
							@voice.log "#{msg.verbose_name} velocity: #{velocity} duration: #{duration}"
							@voice.output.puts MIDIMessage::NoteOn.new(@voice.channel, pitch, velocity) if !@voice.fast_forward?
						else
							@voice.log "silence duration: #{duration}"
						end
					end

					if duration
						this = self
						@voice.sequencer.wait duration - @voice.tick_duration do
							this.note_off velocity: velocity_off
						end
					end
				end

				self
			end

			def note_off(velocity: nil)
				velocity ||= @velocity_off
				velocity = Tool::explode_ranges_on_array(Tool::grant_array(velocity))

				@pitch.each_index do |i|
					pitch = @pitch[i]
					velocity_off = velocity[i % velocity.size]

					if !silence?(pitch)
						@voice.used_pitches[pitch][:counter] -= 1
						@voice.used_pitches[pitch][:counter] = 0 if @voice.used_pitches[pitch][:counter] < 0

						if @voice.used_pitches[pitch][:counter] == 0
							msg = MIDIMessage::NoteOff.new(@voice.channel, pitch, velocity)
							@voice.log "#{msg.verbose_name}"
							@voice.output.puts msg if !@voice.fast_forward?
						end
					end
				end

				@do_on_stop.each do |do_on_stop|
					@voice.sequencer.wait 0, &do_on_stop
				end

				@do_after.each do |do_after|
					@voice.sequencer.wait @voice.tick_duration + do_after[:bars], &do_after[:block]
				end

				nil
			end

			def silence?(pitch)
				pitch.nil? || pitch == :silence
			end

			def on_stop(&block)
				@do_on_stop << block
				nil
			end

			def after(bars = 0, &block)
				@do_after << { bars: bars.rationalize, block: block }
				nil
			end
		end
	end
end