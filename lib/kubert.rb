require 'kubeclient'
require 'ky'
require 'open3'
require 'fiber'
require_relative "kubert/pods"
require_relative "kubert/deployment"

module Kubert
  extend self
  DEFAULT_KUBE_CONFIG_PATH = '~/.kube/config'
  def kube_config
    @kube_config ||= Kubeclient::Config.read(File.expand_path(kube_config_path))
  end

  def kube_config_path
    configuration[:kube_config_path] || DEFAULT_KUBE_CONFIG_PATH
  end

  def contexts
    configuration[:contexts] || []
  end

  def task_pod
    configuration[:task_pod] || random_pod_type
  end

  def default_environment
    configuration[:default_environment]
  end

  def default_namespace
    configuration[:default_namespace] || configuration[:default_environment]
  end

  def context
    kube_config.contexts.select {|c| kube_config.context.api_endpoint.match(c) }
  end

  def console_command
    Array(configuration[:console_command] && configuration[:console_command].split(" "))
  end

  def command_prefix
    configuration[:command_prefix]
  end

  def excluded_deployments
    configuration[:excluded_deployments] || []
  end

  def ky_configuration
    @ky_configuration ||= KY::Configuration.new
  end

  def ky_active?
    ky_configuration[:image] && ky_configuration[:deployment] && ky_configuration[:procfile_path]
  end

  def configuration
    @config ||= (ky_configuration[:kubert] || {}).merge(project_name: ky_configuration[:project_name])
  end

  def client
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

  private

  def random_pod_type
    Kubert.client.get_pods(namespace: current_namespace)
    .sample
    .metadata
    .name
    .split("-")
    .first
  end

  def current_namespace
    ky_configuration[:namespace]        ||
    default_namespace                   ||
    (raise "MUST DEFINE A NAMESPACE FOR POD OPERATIONS, ky namespace, default_namespace or default_environment")
  end

end
