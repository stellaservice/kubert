module Kubert
  class Environment
    PEEK_LENGTH = 4
    def self.get(key, options)
      new(key, nil, options).get
    end

    def self.set(key, value, options)
      new(key, value, options).set
    end

    def self.unset(key, options)
      new(key, nil, options).set
    end

    def initialize(key, value, raw_options)
      @key      = key
      @value    = value
      @options  = raw_options.with_indifferent_access
      abort("ERROR: Cannot specify env set as both new_secret and new_config") if options[:new_config] && options[:new_secret]
      Kubert.ky_configuration(options) # memoizes and avoids passing to FileAccess
      @config_data = FileAccess.new(:config, yaml_key)
      @secret_data = FileAccess.new(:secret, yaml_key)
      return if print_all?
      @create_mode      = (options[:new_config] || options[:new_secret])&.to_sym
    end

    def set
      if create_mode
        abort("ERROR: #{key} exists but #{create_mode} flag set! Call without flag to update existing value") unless total_found == 0
        create
      else
        report_unchanged if existing_value == value
        update
      end
    end

    def get
      return get_all if print_all?
      case total_found
      when 0
        puts "#{yaml_key} not found in configmap or secrets"
      when 1
        puts existing_value
      else
        puts "ERROR! multiple entries found for key: config - #{config_data.found}, secret - #{secret_data.found}"
      end
    end

    private
    attr_reader :key, :value, :options, :create_mode, :config_data, :secret_data

    def print_all?
      key.nil? && value.nil?
    end

    def get_all
      puts "CONFIGMAP:"
      output_hash(config_data.data[:data])
      puts "SECRETS:"
      output_hash(options[:cleartext_secrets] ? secret_data.data[:data] : obscured_secrets)
    end

    def output_hash(hsh)
      hsh.each {|k, v| puts "#{k}: #{v}" }
    end

    def create
      case create_mode
      when :new_secret
        secret_data.set(value).write
      when :new_config
        config_data.set(value).write
      else
        abort("ERROR: unknown create env type error")
      end
    end

    def update
      if secret_data.found.any?
        secret_data.set(value).write
      elsif config_data.found.any?
        config_data.set(value).write
      else
        abort("ERROR: your key is new, must specify secret or configmap with flag")
      end
    end

    def obscured_secrets
      values = secret_data.data[:data].values
      secret_data.data[:data].keys.zip(
        values.map do |secret|
          obscure_length = [(secret.size - PEEK_LENGTH), 0].max
          sneak_peek = secret.slice(obscure_length, secret.size)
          "#{'*' * obscure_length}#{sneak_peek}"
        end
      )
    end

    def insert_ordered_hash(hsh)
      hsh[:data][yaml_key] = value
      hsh[:data] = hsh[:data].sort.to_h
    end

    def existing_value
      config_data.found.merge(secret_data.found).values.first
    end

    def total_found
      secret_data.found.size + config_data.found.size
    end

    def report_unchanged
      puts "WARN: #{key} value unchanged, already set to #{value}"
    end

    def yaml_key
      key&.downcase&.dasherize
    end

  end
end