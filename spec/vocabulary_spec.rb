# frozen_string_literal: true

require 'open3'

# `docs/vocabulary.md` is generated from two things that move: the published API
# and what the subsystem documents name. A generated file that is not checked is
# a file that is wrong -- and this one is worse than most, because it is the page
# a reader consults to find out what EXISTS, so a stale entry sends them looking
# for something that is gone and a missing one hides what is there.
#
# The check is regeneration: build it again and compare. That also means the fix
# is always the same one line, printed in the failure.
RSpec.describe 'docs/vocabulary.md' do
  it 'is current' do
    root = File.expand_path('..', __dir__)

    output, status = Open3.capture2e('bundle', 'exec', 'ruby', 'tools/vocabulary.rb', '--check', chdir: root)

    expect(status).to be_success, output
  end
end
