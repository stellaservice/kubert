require 'Kubeclient'
require_relative "kubert/pods"

module Kubert
  def self.client
    @client ||= begin
      kube_client_config = Kubeclient::Config.read(File.expand_path('~/.kube/config'))
      Kubeclient::Client.new(
        kube_client_config.context.api_endpoint,
          kube_client_config.context.api_version,
          {
            ssl_options: kube_client_config.context.ssl_options,
            auth_options: kube_client_config.context.auth_options
          }
      )
    end
  end
end
