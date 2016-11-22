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

      end
    end
  end
end
