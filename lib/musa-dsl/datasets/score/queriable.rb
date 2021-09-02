module Musa::Datasets
  class Score
    module Queriable
      module QueryableByTimeSlot
        def group_by_attribute(attribute)
          group_by { |e| e[attribute] }.transform_values! { |e| e.extend(QueryableByTimeSlot) }
        end

        def select_by_attribute(attribute, value = nil)
          if value.nil?
            select { |e| !e[attribute].nil? }
          else
            select { |e| e[attribute] == value }
          end.extend(QueryableByTimeSlot)
        end

        def sort_by_attribute(attribute)
          select_by_attribute(attribute).sort_by { |e| e[attribute] }.extend(QueryableByTimeSlot)
        end
      end

      private_constant :QueryableByTimeSlot

      module QueryableByDataset
        def group_by_attribute(attribute)
          group_by { |e| e[:dataset][attribute] }.transform_values! { |e| e.extend(QueryableByDataset) }
        end

        def select_by_attribute(attribute, value = nil)
          if value.nil?
            select { |e| !e[:dataset][attribute].nil? }
          else
            select { |e| e[:dataset][attribute] == value }
          end.extend(QueryableByDataset)
        end

        def subset
          raise ArgumentError, "subset needs a block with the inclusion condition on the dataset" unless block_given?
          select { |e| yield e[:dataset] }.extend(QueryableByDataset)
        end

        def sort_by_attribute(attribute)
          select_by_attribute(attribute).sort_by { |e| e[:dataset][attribute] }.extend(QueryableByDataset)
        end
      end

      private_constant :QueryableByDataset
    end
end; end