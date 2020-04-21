require 'spec_helper'

require 'musa-dsl'

include Musa::Neumalang
include Musa::Datasets
include Musa::Neumas

RSpec.describe Musa::Neumalang do
  context 'Neuma process parsing' do
    it 'Basic process' do
      s = <<~string
        (a: 1 b: 2 c: 3) !4 (a: 3 b: 5 c: 7) !4 (a: 1 b: 2 c: 0)
      string
    end

    it '' do
      s = <<~string

        (a: 1 b: 2 c: 3) !4!
        (a: 1 b: 2 c: 3) !4.5! .do_something()
        (a: 1 b: 2 c: 3) !9/2! .do_something()

        (a: 1 b: 2 c: 3) !4 (a: 1 b: 2 c: 3)
        (a: 1 b: 2 c: 3) !4 (a: 1 b: 2 c: 3) .do_something() 

        (a: 1 b: 2 c: 3) !4 (a: 1 b: 2 c: 3) !2
        (a: 1 b: 2 c: 3) !4 (a: 1 b: 2 c: 3)

        (a: 1 b: 2 c: 3) !4 (a: 1 b: 2 c: 3).do_something() 

        [(a: 1 b: 2 c: 3) |4| (a: 1 b: 2 c: 3)].do_something() 
        [(a: 1 b: 2 c: 3) || (a: 1 b: 2 c: 3)].do_something() 
        [(a: 1 b: 2 c: 3) || (a: 1 b: 2 c: 3)].do_something() 

        ????

      string

    end



    it 'process of gd' do
      s = <<~string
        abc_to_gv * (a: 1 b: 2 c: 3) !4 abc_to_gv * (a: 3 b: 5 c: 7) !4 abc_to_gv * (a: 1 b: 2 c: 0)
      string


    end

    it '' do
      s = <<~string
        abc_to_gdv * ((a: 1 b: 2 c: 3) !4 (a: 3 b: 5 c: 7) !4 (a: 1 b: 2 c: 0))
      string
    end

    it '' do
      s = <<~string
        gdvmapper * abc_to_gdv * (a: 1 b: 2 c: 3) !4 (a: 3 b: 5 c: 7) !4 (a: 1 b: 2 c: 0)
      string
    end




  end

end
