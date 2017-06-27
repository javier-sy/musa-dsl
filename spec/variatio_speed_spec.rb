require 'musa-dsl'
require 'benchmark'
require 'profile'


=begin Tras eliminar el uso de & en el paso de parámetros de tipo Proc

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                           2.280000   0.020000   2.300000 (  2.314278)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  1.880000   0.010000   1.890000 (  1.899786)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   2.540000   0.030000   2.570000 (  2.591855)
	----------------------------------------------------------------------------------------------------------------------------- total: 6.760000sec

	                                                                                                         user     system      total        real
	With 2 fields and constructor, without external parameters                                           2.200000   0.050000   2.250000 (  2.266223)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  1.830000   0.040000   1.870000 (  1.899216)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   2.390000   0.030000   2.420000 (  2.434498)

=end


=begin Tras emplear KeyParametersBinder en constructor y finalize

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                           1.820000   0.020000   1.840000 (  1.856897)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  1.750000   0.020000   1.770000 (  1.775603)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   2.450000   0.030000   2.480000 (  2.498063)
	----------------------------------------------------------------------------------------------------------------------------- total: 6.090000sec

	                                                                                                         user     system      total        real
	With 2 fields and constructor, without external parameters                                           1.680000   0.040000   1.720000 (  1.727875)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  1.680000   0.030000   1.710000 (  1.727988)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   2.380000   0.020000   2.400000 (  2.413189)

=end

=begin Tras eliminar ** del hash de parámetros en la llamada a @constructor.call y @finalize.call

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                           1.520000   0.020000   1.540000 (  1.546157)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  1.620000   0.010000   1.630000 (  1.649806)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   2.410000   0.030000   2.440000 (  2.449447)
	----------------------------------------------------------------------------------------------------------------------------- total: 5.610000sec

	                                                                                                         user     system      total        real
	With 2 fields and constructor, without external parameters                                           1.500000   0.030000   1.530000 (  1.545742)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  1.600000   0.030000   1.630000 (  1.644844)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   2.360000   0.020000   2.380000 (  2.396809)

=end

=begin Tras emplear KeyParametersProcedureBinder en B.run, eliminando también el ** en la llamada

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                           1.560000   0.020000   1.580000 (  1.587523)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  0.970000   0.010000   0.980000 (  0.990704)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   1.260000   0.030000   1.290000 (  1.292160)
	----------------------------------------------------------------------------------------------------------------------------- total: 3.850000sec

	                                                                                                         user     system      total        real
	With 2 fields and constructor, without external parameters                                           1.420000   0.030000   1.450000 (  1.461399)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                  0.920000   0.010000   0.930000 (  0.938149)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize   1.210000   0.020000   1.230000 (  1.234210)

=end

=begin Tras implementar multithread (1 thread) en la construcción de objetos (no en la evaluación de parámetros); añadido un test más

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                                                         1.610000   0.150000   1.760000 (  1.758505)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                1.140000   0.030000   1.170000 (  1.181842)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.270000   0.030000   1.300000 (  1.311819)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  39.510000   0.560000  40.070000 ( 40.150101)
	---------------------------------------------------------------------------------------------------------------------------------------------------------- total: 44.300000sec

	                                                                                                                                       user     system      total        real
	With 2 fields and constructor, without external parameters                                                                         1.460000   0.210000   1.670000 (  1.651662)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.870000   0.050000   0.920000 (  0.921855)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.160000   0.020000   1.180000 (  1.174421)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  36.390000   0.830000  37.220000 ( 37.295303)

=end

=begin Tras implementar A1.calc_own_parameters con @own_parameters; multithread (1 thread) en la construcción de objetos (no en la evaluación de parámetros)

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                                                         1.620000   0.150000   1.770000 (  1.767122)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.920000   0.030000   0.950000 (  0.954572)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.230000   0.020000   1.250000 (  1.258085)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  37.280000   0.440000  37.720000 ( 37.739326)
	---------------------------------------------------------------------------------------------------------------------------------------------------------- total: 41.690000sec

	                                                                                                                                       user     system      total        real
	With 2 fields and constructor, without external parameters                                                                         1.430000   0.210000   1.640000 (  1.622888)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.860000   0.050000   0.910000 (  0.906855)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.100000   0.010000   1.110000 (  1.114683)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  34.300000   1.040000  35.340000 ( 35.354782)

=end

=begin Tras implementar A2.calc_own_parameters con @own_parameters y A.calc_parameters con @calc_parameters; multithread (1 thread) en la construcción de objetos (no en la evaluación de parámetros)

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                                                         1.530000   0.130000   1.660000 (  1.665409)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.940000   0.030000   0.970000 (  0.964657)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.200000   0.020000   1.220000 (  1.235634)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  36.600000   0.480000  37.080000 ( 37.106043)
	---------------------------------------------------------------------------------------------------------------------------------------------------------- total: 40.930000sec

	                                                                                                                                       user     system      total        real
	With 2 fields and constructor, without external parameters                                                                         1.450000   0.230000   1.680000 (  1.664934)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.830000   0.050000   0.880000 (  0.883442)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.070000   0.010000   1.080000 (  1.081921)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  35.680000   1.220000  36.900000 ( 36.909661)

=end

=begin multithread (4 threads) en la construcción de objetos (no en la evaluación de parámetros)

	Rehearsal --------------------------------------------------------------------------------------------------------------------------------------------------------------------
	With 2 fields and constructor, without external parameters                                                                         1.840000   0.510000   2.350000 (  2.136168)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.990000   0.070000   1.060000 (  1.050283)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.240000   0.030000   1.270000 (  1.271406)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  36.760000   0.490000  37.250000 ( 37.272603)
	---------------------------------------------------------------------------------------------------------------------------------------------------------- total: 41.930000sec

	                                                                                                                                       user     system      total        real
	With 2 fields and constructor, without external parameters                                                                         1.730000   0.680000   2.410000 (  2.193344)
	With 2 fields + fieldset (2 inner fields), constructor and finalize                                                                0.920000   0.110000   1.030000 (  1.007805)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize                                 1.200000   0.010000   1.210000 (  1.211774)
	With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize  35.130000   0.980000  36.110000 ( 36.103642)



=end


RSpec.describe Musa::Variatio do
	context "Create several kind of variations, speed measurements" do

		
		v1 = Musa::Variatio.new :object do
			field :a, 1..10
			field :b, [:alfa, :beta, :gamma, :delta]

			constructor do |a:, b:|
				{ a: a, b: b }
			end
		end

		v2 = Musa::Variatio.new :object do

			field :a
			field :b, [0, 1]
			field :c, [2, 3]

			constructor do |a:, b:|
				{ a: a, b: b, d: {} }
			end

			finalize do |object:|
				object[:finalized] = true
			end

			with_attributes do |object:, c:|
				object[:c] = c
			end

			fieldset :d, [100, 101] do

				field :e, [4, 5]
				field :f, [6, 7]

				with_attributes do |object:, d:, e:, f:|
					object[:d][d] = {}
					object[:d][d][:e] = e
					object[:d][d][:f] = f
				end
			end
		end

		v3 = Musa::Variatio.new :object do

			field :a
			field :b, [0, 1]
			field :c, [2, 3]

			constructor do |a:, b:|
				{ a: a, b: b, d: {} }
			end

			finalize do |object:|
				object[:finalized] = true
			end

			with_attributes do |object:, c:|
				object[:c] = c
			end

			fieldset :d, [100, 101] do

				field :e, [4, 5]
				field :f, [6, 7]

				with_attributes do |object:, d:, e:, f:|

					object[:d][d] ||= {}
					object[:d][d][:e] = e
					object[:d][d][:f] = f
				end

				fieldset :g, [200, 201] do
					
					field :h, [8, 9]
					field :i, [10, 11]

					with_attributes do |object:, d:, g:, h:, i:|
						object[:d][d][:g] ||= {}
						object[:d][d][:g][g] ||= {}

						object[:d][d][:g][g][:h] = h
						object[:d][d][:g][g][:i] = i
					end
				end
			end
		end



		v4 = Musa::Variatio.new :object do

			field :a
			field :b, [0, 1]
			field :c, [2, 3]

			constructor do |a:, b:|
				{ a: a, b: b, d: {} }
			end

			finalize do |object:|
				object[:finalized] = true
			end

			with_attributes do |object:, c:|
				object[:c] = c
			end

			fieldset :d, [100, 101] do

				field :e, [4, 5]
				field :f, [6, 7]

				with_attributes do |object:, d:, e:, f:|

					object[:d][d] ||= {}
					object[:d][d][:e] = e
					object[:d][d][:f] = f
				end

				fieldset :g, [200, 201] do
					
					field :h, [8, 9]
					field :i, [10, 11]

					with_attributes do |object:, d:, g:, h:, i:|
						object[:d][d][:g] ||= {}
						object[:d][d][:g][g] ||= {}

						object[:d][d][:g][g][:h] = h
						object[:d][d][:g][g][:i] = i
					end
				end

				fieldset :j, [300, 301] do
					
					field :k, [12, 13]

					with_attributes do |object:, d:, j:, k:|
						object[:d][d][:j] ||= {}
						object[:d][d][:j][j] ||= {}

						object[:d][d][:j][j][:k] = k
					end
				end
			end
		end



		Benchmark.bmbm do |x|
#			x.report("With 2 fields and constructor, without external parameters") { 1.upto(5000) { variations = v1.run } }
#			x.report("With 2 fields + fieldset (2 inner fields), constructor and finalize") { 1.upto(500) { variations = v2.on a: 1000 } }
			x.report("With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize") { 1.upto(1) { variations = v3.on a: 1000 } }
#			x.report("With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize") { 1.upto(1) { variations = v4.on a: 1000 } }
		end
	end
end
