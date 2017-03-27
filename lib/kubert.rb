require 'kubeclient'
require 'ky'
require 'open3'
require_relative "kubert/pods"
require_relative "kubert/deployment"

module Kubert
  def self.kube_config
    @kube_config ||= Kubeclient::Config.read(File.expand_path('~/.kube/config'))
  end

  def self.contexts
    configuration[:contexts] || []
  end

  def self.default_environment
    configuration[:default_environment]
  end

  def self.context
    kube_config.contexts.select {|c| kube_config.context.api_endpoint.match(c) }
  end

  def self.excluded_deployments
    configuration[:excluded_deployments] || []
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
