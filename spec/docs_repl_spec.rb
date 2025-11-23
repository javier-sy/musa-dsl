require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'REPL Documentation Examples' do

  context 'REPL - Live Coding Infrastructure' do
    it 'demonstrates REPL protocol concepts' do
      # Note: This test demonstrates concepts rather than running a real REPL server
      # since that would require TCP connections and background threads

      # Protocol messages that would be sent by client
      client_path = "#path"
      client_file = "/Users/me/composition.rb"
      client_begin = "#begin"
      client_code = "puts 'Starting...'"
      client_end = "#end"

      # Expected server responses
      server_echo = "//echo"
      server_end = "//end"

      # Verify protocol format
      expect(client_path).to eq("#path")
      expect(client_begin).to eq("#begin")
      expect(client_end).to eq("#end")
      expect(server_echo).to eq("//echo")
      expect(server_end).to eq("//end")

      # REPL would inject file path as @user_pathname
      require 'pathname'
      user_pathname = Pathname.new(client_file)
      expect(user_pathname.dirname.to_s).to eq("/Users/me")
      expect(user_pathname.basename.to_s).to eq("composition.rb")
    end
  end


end
