module Kubert
  module Configuration
    DEFAULT_KUBE_CONFIG_PATH = '~/.kube/config'
    def kube_config
      @kube_config ||= Kubeclient::Config.read(File.expand_path(kube_config_path))
    end

    # Config methods which correspond to config or default value/value_method
    {
      default_environment: nil,
      command_prefix: nil,
      kube_config_path: DEFAULT_KUBE_CONFIG_PATH,
      contexts: [],
      excluded_deployments: [],
      task_pod: :random_pod_type,
      default_namespace: :default_environment
    }.each do |config, default_value|
      define_method(config) do
        return configuration[config] if configuration[config]
        default_value.is_a?(Symbol) ? public_send(default_value) : default_value
      end
    end

    def context
      kube_config.contexts.select {|c| kube_config.context.api_endpoint.match(c) }
    end

    def console_command
      Array(configuration[:console_command] && configuration[:console_command].split(" "))
    end

    def ky_configuration(options={})
      @ky_configuration ||= KY::Configuration.new({environment: Kubert.default_environment, namespace: Kubert.default_namespace}.merge(options))
    end

    def ky_active?
      ky_configuration[:image] && ky_configuration[:deployment] && ky_configuration[:procfile_path]
    end

    def configuration
      @configuration ||= begin
        temp_ky_configuration = KY::Configuration.new
        (temp_ky_configuration[:kubert] || {}).merge(project_name: temp_ky_configuration[:project_name])
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
end