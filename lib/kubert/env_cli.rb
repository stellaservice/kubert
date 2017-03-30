require 'thor'
module Kubert
  class EnvCli < Thor
    desc "env get", "Get named env value from configmap or secrets, or all of both if none specified"
    method_option :environment, type: :string, aliases: "-e"
    method_option :configmap_path, type: :string, aliases: "-k"
    method_option :secrets_path, type: :string, aliases: "-p"
    method_option :cleartext_secrets, type: :string, aliases: "-c"
    def get(key=nil)
      Environment.get(key, options)
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