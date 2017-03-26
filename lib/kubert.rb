require 'kubeclient'
require 'ky'
require 'open3'
require_relative "kubert/pods"

module Kubert
  def self.kube_config
    @kube_config ||= Kubeclient::Config.read(File.expand_path('~/.kube/config'))
  end

  def self.contexts
    configuration[:contexts] || []
  end

  def self.configuration
    @config ||= begin
      config = KY::Configuration.new
      (config[:kubert] || {}).merge(project_name: config[:project_name])
    end
  end

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
