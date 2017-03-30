require 'thor'
module Kubert
  class EnvCli < Thor
    desc "env all", "Get all keys and values from configmap and secrets"
    method_option :environment, type: :string, aliases: "-e"
    method_option :configmap_path, type: :string, aliases: "-k"
    method_option :secrets_path, type: :string, aliases: "-p"
    method_option :cleartext_secrets, type: :string, aliases: "-c"
    def all
      Environment.get(nil, options)
    end

    desc "env get", "Get named env value from configmap or secrets"
    method_option :environment, type: :string, aliases: "-e"
    method_option :configmap_path, type: :string, aliases: "-k"
    method_option :secrets_path, type: :string, aliases: "-p"
    def get(key)
      Environment.get(key, options)
    end

    desc "env unset", "Clear named env value from configmap or secrets, error if not present"
    method_option :environment, type: :string, aliases: "-e"
    method_option :configmap_path, type: :string, aliases: "-k"
    method_option :secrets_path, type: :string, aliases: "-p"
    method_option :cleartext_secrets, type: :string, aliases: "-c"
    def unset(key)
      Environment.unset(key, options)
    end

    method_option :environment, type: :string, aliases: "-e"
    method_option :configmap_path, type: :string, aliases: "-k"
    method_option :secrets_path, type: :string, aliases: "-p"
    method_option :new_secret, type: :string, aliases: "-s"
    method_option :new_config, type: :string, aliases: "-c"
    desc "env set", "change existing env value in configmap or secrets, or new one with flag option"
    def set(key, value)
      Environment.set(key, value, options)
    end

  end
end