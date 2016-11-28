module Voltron
  class Encrypt
    module ActiveRecord
      module CollectionAssociation

        def ids_writer(ids)
          if klass.has_encrypted_id?
            ids.reject!(&:blank?)
            replace(klass.find(ids))
          else
            super ids
          end
        end

        def ids_reader
          if loaded?
            load_target.map do |record|
              if klass.has_encrypted_id?
                record.to_param
              else
                record.send(reflection.association_primary_key)
              end
            end
          else
            if klass.has_encrypted_id?
              scope.map(&:to_param)
            else
              column  = "#{reflection.quoted_table_name}.#{reflection.association_primary_key}"
              scope.pluck(column)
            end
          end
        end

      end
    end
  end
end
