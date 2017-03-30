module Kubert
  class Environment
    PEEK_LENGTH = 4
    def self.get(key, options)
      new(key, nil, options).get
    end

    def self.set(key, value, options)
      new(key, value, options).set
    end

    def initialize(key, value, raw_options)
      @key      = key
      @value    = value
      @options  = raw_options.with_indifferent_access
      abort("ERROR: Cannot specify env set as both new_secret and new_config") if options[:new_config] && options[:new_secret]
      @config_data, @secret_data = parse_yaml(:config_path), parse_yaml(:secret_path)
      return if print_all?
      @found_config = config_data[:data].select {|k, v| k == yaml_key }
      @found_secret = secret_data[:data].select {|k, v| k == yaml_key }
      @create_mode = (options[:new_config] || options[:new_secret])&.to_sym
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
        puts "ERROR! multiple entries found for key: config - #{found_config}, secret - #{found_secret}"
      end
    end

    private
    attr_reader :key, :value, :options, :create_mode, :config_data, :secret_data, :found_config, :found_secret

    def print_all?
      key.nil? && value.nil?
    end

    def get_all
      puts "CONFIGMAP:"
      output_hash(config_data[:data])
      puts "SECRETS:"
      output_hash(options[:cleartext_secrets] ? secret_data[:data] : obscured_secrets)
    end

    def output_hash(hsh)
      hsh.each {|k, v| puts "#{k}: #{v}" }
    end

    def create
      case create_mode
      when :new_secret
        insert_ordered_hash(secret_data)
        File.write(env_file_path(:secret_path), secret_data.to_plain_yaml)
      when :new_config
        insert_ordered_hash(config_data)
        File.write(env_file_path(:config_path), config_data.to_plain_yaml)
      else
        abort("ERROR: unknown create env type error")
      end
    end

    def update
      if found_secret.any?
        insert_ordered_hash(secret_data)
        File.write(env_file_path(:secret_path), secret_data.to_plain_yaml)
      elsif found_config.any?
        insert_ordered_hash(config_data)
        File.write(env_file_path(:config_path), config_data.to_plain_yaml)
      else
        abort("ERROR: your key is new, must specify secret or configmap with flag")
      end
    end

    def obscured_secrets
      values = secret_data[:data].values
      secret_data[:data].keys.zip(
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
      found_config.merge(found_secret).values.first
    end

    def total_found
      found_secret.size + found_config.size
    end

    def report_unchanged
      puts "WARN: #{key} value unchanged, already set to #{value}"
    end

    def yaml_key
      key.downcase.dasherize
    end

    def parse_yaml(env_key)
      YAML.load(File.read(env_file_path(env_key))).with_indifferent_access
    end

    def env_file_path(env_key)
      Kubert.ky_configuration(options)[env_key]
    end
  end
end