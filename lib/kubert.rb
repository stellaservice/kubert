require 'kubeclient'
require 'ky'
require 'open3'
require 'fiber'
require_relative "kubert/pods"
require_relative "kubert/deployment"
require_relative "kubert/environment"
require_relative "kubert/configuration"
require_relative "kubert/env_cli"

module Kubert
  extend Configuration
  def self.client
    @client ||= begin
      Kubeclient::Client.new(
        kube_config.context.api_endpoint,
          kube_config.context.api_version,
          {
            ssl_options: kube_config.context.ssl_options,
            auth_options: kube_config.context.auth_options
          }
      )
    end
  end
end
