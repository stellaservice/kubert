module Kubert
  class Deployment
    def self.perform(options)
      new(options).perform
    end

    def self.rollback(options)
      new(options).rollback
    end

    attr_reader :project_name, :deployments, :options, :operation_statuses
    def initialize(options, project_name= Kubert.configuration[:project_name])
      @project_name = project_name
      @deployments = []
      @options = options
    end

    def rollback
      confirm :rollback do
        compilation.deploy_generation.proc_commands.keys.each do |deployment_name|
          perform_with_status { `kubectl rollout status deployment/#{deployment_name} #{namespace_flag}` } unless excluded?(deployment_name)
        end
        report_status(:rollback)
      end
    end

    def perform
      confirm :deploy do
        perform_with_status { `kubectl apply -f #{output_dir}/#{Kubert.config_file_name}` }
        perform_with_status {`kubectl apply -f #{output_dir}/#{Kubert.secret_file_name}` }
        compilation.deploy_generation.to_h.each do |deployment_file, _template_hash|
          perform_with_status { `kubectl apply -f #{deployment_file}` unless excluded?(deployment_file) }
        end
        report_status(:deploy)
      end
    end

    def compilation
      @compilation ||= KY::API.compile(options[:configmap_path], options[:secrets_path], options[:output_dir], options_with_defaults)
    end

    private

    def confirm(action)
      unless ENV['SKIP_CONFIRMATION']
        puts "Press any key to confirm, ctl-c to abort: #{action.to_s.upcase} on #{Kubert.context}"
        $stdin.gets
      end
      yield
    rescue Interrupt
      puts "Aborting #{action}"
    end

    def report_status(action)
      puts "All #{action} steps ran successfully"
    end

    def perform_with_status
      output = yield
      abort(output) unless $?.success?
    end

    def options_with_defaults
      (options[:environment] ? options : options.merge(environment: Kubert.default_environment)).with_indifferent_access
    end

    def ky_configuration
      @ky_configuration ||= compilation.deploy_generation.configuration.configuration.with_indifferent_access
    end

    def namespace_flag
      return unless compilation.configuration[:environment]
      "-n #{compilation.configuration[:environment]} "
    end

    def excluded?(deployment_info)
      Kubert.excluded_deployments.any? {|deploy| deployment_info.match(deploy) }
    end

    def output_dir
      compilation.deploy_generation.full_output_dir
    end
  end
end