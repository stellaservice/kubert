module Kubert
  class Deployment
    def self.perform(options)
      new(options).perform
    end

    def self.rollback(options)
      new(options).rollback
    end

    attr_reader :project_name, :deployments, :options
    def initialize(options, project_name= Kubert.configuration[:project_name])
      @project_name = project_name
      @deployments = []
      @options = options
    end

    def rollback
      confirm "rollback" do
        compilation.deploy_generation.proc_commands.keys.each do |deployment_name|
          `kubectl rollout status deployment/#{deployment_name} #{namespace_flag}` unless excluded?(deployment_name)
        end
      end
    end

    def perform
      confirm "deploy" do
        compilation.deploy_generation.to_h.each do |deployment_file, _template_hash|
          `kubectl apply -f #{deployment_file}` unless excluded?(deployment_file)
        end
      end
    end

    def compilation
      @compilation ||= KY::API.compile(options[:configmap_path], options[:secrets_path], options[:output_dir], options_with_defaults)
    end

    private

    def confirm(action)
      unless ENV['SKIP_CONFIRMATION']
        puts "Press any key to confirm, ctl-c to abort: #{action.upcase} on #{Kubert.context}"
        $stdin.gets
      end
      yield
    end

    def options_with_defaults
      (options[:environment] ? options : options.merge(environment: Kubert.default_environment)).with_indifferent_access
    end


    def namespace_flag
      return unless compilation.configuration[:environment]
      "-n #{compilation.configuration[:environment]} "
    end

    def excluded?(deployment_info)
      Kubert.excluded_deployments.any? {|deploy| deployment_info.match(deploy) }
    end
  end
end