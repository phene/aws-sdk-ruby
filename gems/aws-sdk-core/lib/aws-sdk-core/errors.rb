module Aws
  module Errors

    class NonSupportedRubyVersionError < RuntimeError; end

    # The base class for all errors returned by an Amazon Web Service.
    # All ~400 level client errors and ~500 level server errors are raised
    # as service errors.  This indicates it was an error returned from the
    # service and not one generated by the client.
    class ServiceError < RuntimeError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::Structure] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        @code = self.class.code
        @message = message if message && !message.empty?
        @context = context
        @data = data
        super(message)
      end

      # @return [String]
      attr_reader :code

      # @return [Seahorse::Client::RequestContext] The context of the request
      #   that triggered the remote service to return this error.
      attr_reader :context

      # @return [Aws::Structure]
      attr_reader :data

      class << self

        # @return [String]
        attr_accessor :code

      end

      # @return [Boolean] (false) Error is a retryable exception.
      def retryable?
        false
      end

      # @return [Boolean] (false) Error is a retryable throttling exception.
      def throttling?
        false
      end
    end

    # Raised when InstanceProfileCredentialsProvider or
    # EcsCredentialsProvider fails to parse the metadata response after retries
    class MetadataParserError < RuntimeError
      def initialize(*args)
        msg = "Failed to parse metadata service response."
        super(msg)
      end
    end

    # Raised when a `streaming` operation has `requiresLength` trait
    # enabled but request payload size/length cannot be calculated
    class MissingContentLength < RuntimeError
      def initialize(*args)
        msg = 'Required `Content-Length` value missing for the request.'
        super(msg)
      end
    end

    # Rasied when endpoint discovery failed for operations
    # that requires endpoints from endpoint discovery
    class EndpointDiscoveryError < RuntimeError
      def initialize(*args)
        msg = 'Endpoint discovery failed for the operation or discovered endpoint is not working, '\
          'request will keep failing until endpoint discovery succeeds or :endpoint option is provided.'
        super(msg)
      end
    end

    # raised when hostLabel member is not provided
    # at operation input when endpoint trait is available
    # with 'hostPrefix' requirement
    class MissingEndpointHostLabelValue < RuntimeError

      def initialize(name)
        msg = "Missing required parameter #{name} to construct"\
          " endpoint host prefix. You can disable host prefix by"\
          " setting :disable_host_prefix_injection to `true`."
        super(msg)
      end

    end

    # Raised when attempting to #signal an event before
    # making an async request
    class SignalEventError < RuntimeError; end

    # Raised when EventStream Parser failed to parse
    # a raw event message
    class EventStreamParserError < RuntimeError; end

    # Raise when EventStream Builder failed to build
    # an event message with parameters provided
    class EventStreamBuilderError < RuntimeError; end

    # Error event in an event stream which has event_type :error
    # error code and error message can be retrieved when available.
    #
    # example usage:
    #
    #   client.stream_foo(name: 'bar') do |event|
    #     stream.on_error_event do |event|
    #       puts "Error #{event.error_code}: #{event.error_message}"
    #       raise event
    #     end
    #   end
    #
    class EventError < RuntimeError

      def initialize(event_type, code, message)
        @event_type = event_type
        @error_code = code
        @error_message = message
      end

      # @return [Symbol]
      attr_reader :event_type

      # @return [String]
      attr_reader :error_code

      # @return [String]
      attr_reader :error_message

    end

    # Raised when ARN string input doesn't follow the standard:
    # https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-arns
    class InvalidARNError < RuntimeError; end

    # Raised when the region from the ARN string is different from the :region
    # configured on the service client.
    class InvalidARNRegionError < RuntimeError
      def initialize(*args)
        msg = 'ARN region is different from the configured client region.'
        super(msg)
      end
    end

    # Raised when the partition of the ARN region is different than the
    # partition of the :region configured on the service client.
    class InvalidARNPartitionError < RuntimeError
      def initialize(*args)
        msg = 'ARN region partition is different from the configured '\
              'client region partition.'
        super(msg)
      end
    end

    # Various plugins perform client-side checksums of responses.
    # This error indicates a checksum failed.
    class ChecksumError < RuntimeError; end

    # Raised when a client is constructed and the specified shared
    # credentials profile does not exist.
    class NoSuchProfileError < RuntimeError; end

    # Raised when a client is constructed, where Assume Role credentials are
    # expected, and there is no source profile specified.
    class NoSourceProfileError < RuntimeError; end

    # Raised when a client is constructed with Assume Role credentials using
    # a credential_source, and that source type is unsupported.
    class InvalidCredentialSourceError < RuntimeError; end

    # Raised when a client is constructed with Assume Role credentials, but
    # the profile has both source_profile and credential_source.
    class CredentialSourceConflictError < RuntimeError; end

    # Raised when a client is constructed with Assume Role credentials using
    # a credential_source, and that source doesn't provide credentials.
    class NoSourceCredentialsError < RuntimeError; end

    # Raised when a client is constructed and credentials are not
    # set, or the set credentials are empty.
    class MissingCredentialsError < RuntimeError
      def initialize(*args)
        msg = 'unable to sign request without credentials set'
        super(msg)
      end
    end

    # Raised when :web_identity_token_file parameter is not
    # provided or the file doesn't exist when initializing
    # AssumeRoleWebIdentityCredentials credential provider
    class MissingWebIdentityTokenFile < RuntimeError
      def initialize(*args)
        msg = 'Missing :web_identity_token_file parameter or'\
          ' invalid file path provided for'\
          ' Aws::AssumeRoleWebIdentityCredentials provider'
        super(msg)
      end
    end

    # Raised when a credentials provider process returns a JSON
    # payload with either invalid version number or malformed contents
    class InvalidProcessCredentialsPayload < RuntimeError; end

    # Raised when a client is constructed and region is not specified.
    class MissingRegionError < ArgumentError
      def initialize(*args)
        msg = "missing region; use :region option or "
        msg << "export region name to ENV['AWS_REGION']"
        super(msg)
      end
    end

    # Raised when attempting to connect to an endpoint and a `SocketError`
    # is received from the HTTP client. This error is typically the result
    # of configuring an invalid `:region`.
    class NoSuchEndpointError < RuntimeError

      def initialize(options = {})
        @context = options[:context]
        @endpoint = @context.http_request.endpoint
        @original_error = options[:original_error]
        super(<<-MSG)
Encountered a `SocketError` while attempting to connect to:

  #{endpoint.to_s}

This is typically the result of an invalid `:region` option or a
poorly formatted `:endpoint` option.

* Avoid configuring the `:endpoint` option directly. Endpoints are constructed
  from the `:region`. The `:endpoint` option is reserved for certain services
  or for connecting to non-standard test endpoints.

* Not every service is available in every region.

* Never suffix region names with availability zones.
  Use "us-east-1", not "us-east-1a"

Known AWS regions include (not specific to this service):

#{possible_regions}
        MSG
      end

      attr_reader :context

      attr_reader :endpoint

      attr_reader :original_error

      private

      def possible_regions
        Aws.partitions.inject([]) do |region_names, partition|
          partition.regions.each do |region|
            region_names << region.name
          end
          region_names
        end.join("\n")
      end

    end

    # This module is mixed into another module, providing dynamic
    # error classes.  Error classes all inherit from {ServiceError}.
    #
    #     # creates and returns the class
    #     Aws::S3::Errors::MyNewErrorClass
    #
    # Since the complete list of possible AWS errors returned by services
    # is not known, this allows us to create them as needed.  This also
    # allows users to rescue errors by class without them being concrete
    # classes beforehand.
    #
    # @api private
    module DynamicErrors

      def self.extended(submodule)
        submodule.instance_variable_set("@const_set_mutex", Mutex.new)
        submodule.const_set(:ServiceError, Class.new(ServiceError))
      end

      def const_missing(constant)
        set_error_constant(constant)
      end

      # Given the name of a service and an error code, this method
      # returns an error class (that extends {ServiceError}.
      #
      #     Aws::S3::Errors.error_class('NoSuchBucket').new
      #     #=> #<Aws::S3::Errors::NoSuchBucket>
      #
      # @api private
      def error_class(error_code)
        constant = error_class_constant(error_code)
        if error_const_set?(constant)
          # modeled error class exist
          # set code attribute
          err_class = const_get(constant)
          err_class.code = constant.to_s
          err_class
        else
          set_error_constant(constant)
        end
      end

      private

      # Convert an error code to an error class name/constant.
      # This requires filtering non-safe characters from the constant
      # name and ensuring it begins with an uppercase letter.
      # @param [String] error_code
      # @return [Symbol] Returns a symbolized constant name for the given
      #   `error_code`.
      def error_class_constant(error_code)
        constant = error_code.to_s
        constant = constant.gsub(/https?:.*$/, '')
        constant = constant.gsub(/[^a-zA-Z0-9]/, '')
        constant = 'Error' + constant unless constant.match(/^[a-z]/i)
        constant = constant[0].upcase + constant[1..-1]
        constant.to_sym
      end

      def set_error_constant(constant)
        @const_set_mutex.synchronize do
          # Ensure the const was not defined while blocked by the mutex
          if error_const_set?(constant)
            const_get(constant)
          else
            error_class = Class.new(const_get(:ServiceError))
            error_class.code = constant.to_s
            const_set(constant, error_class)
          end
        end
      end

      def error_const_set?(constant)
        # Purposefully not using #const_defined? as that method returns true
        # for constants not defined directly in the current module.
        constants.include?(constant.to_sym)
      end

    end
  end
end
