module Voltron
	module Encryptable

		def encrypted_id
			extend ClassMethods
			include InstanceMethods

			has_one :encryptable, as: :resource, class_name: "Voltron::Id"

			before_create do
				self.build_encryptable id: find_id
			end
		end

		module ClassMethods
			def find(*args)
				scope = args.slice!(0)
				options = args.slice!(0) || {}

				if !options[:bypass] && ![:first, :last, :all].include?(scope.try(:to_sym))
					scope = decoded_ids(scope)
				end
				
				super(scope)
			end

			def exists?(conditions = :none)
				if conditions.is_a?(String)
					# If conditions is a string, assume it's an encoded id
					super(decoded_ids(conditions))
				else
					# Otherwise do what exists? normally does
					super(conditions)
				end
			end

			def destroy(id)
				super(decoded_ids(id))
			end

			def delete(id)
				super(decoded_ids(id))
			end

			private

				def decoded_ids(*ids)
					crypt = Voltron::Encrypt.new

					ids.flatten!
					ids.map! { |id| crypt.decode(id).to_i }
					ids.reject! { |id| id > 9223372036854775807 } # Remove id if given decoded value is greater than max PostgreSQL value
					ids = Voltron::Id.where(id: ids).pluck(:resource_id)
					ids = ids.first if ids.length == 1
					ids
				end
		end

		module InstanceMethods
			def to_param
				return super if encryptable.nil?

				crypt = Voltron::Encrypt.new
				crypt.encode(encryptable.id)
			end

			def find_id
				amount = Voltron::Id.count.to_f
				factor = 256.to_f
				min = (((amount/factor).floor*factor) + 1).to_i
				max = (((amount+1)/factor).ceil*factor).to_i
				used = Voltron::Id.where(id: min..max).pluck(:id)
				ids = ((min..max).to_a - used).shuffle
				candidate = ids.first

				if crypt.blacklisted?(candidate)
					# If id chosen is a blacklisted word, insert it as a placeholder record and try again
					Voltron::Id.create(id: candidate, resource_id: 0, resource_type: :blacklist)
					find_id
				else
					# The id chosen is good, not a blacklisted word. Use it
					candidate
				end
			end

			def reload(options = nil)
				clear_aggregation_cache
				clear_association_cache
				self.class.connection.clear_query_cache

				fresh_object =
					if options && options[:lock]
						self.class.unscoped { self.class.lock(options[:lock]).find_by(id: encryptable.resource_id) }
					else
						self.class.unscoped { self.class.find(encryptable.resource_id, bypass: true) }
					end

				@attributes = fresh_object.instance_variable_get("@attributes")
				@new_record = false
				self
			end

			private

				def crypt
					@crypt ||= Voltron::Encrypt.new
				end
		end
	end
end