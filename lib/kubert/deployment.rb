module Kubert
  class Deployment
    def self.perform(options)
      new(options).perform
    end

    def self.rollback(options)
      new(options).rollback
    end

    attr_reader :project_name, :options, :operation_statuses
    def initialize(options, project_name= Kubert.configuration[:project_name])
      @project_name = project_name
      @options = options
      Kubert.ky_configuration(options) # memoize options for FileAccess usage
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
        handle_env_deploy do
          compilation.deploy_generation.to_h.each do |deployment_file, _template_hash|
            perform_with_status { `kubectl apply -f #{File.expand_path(deployment_file)} --record` unless excluded?(deployment_file) }
          end
          report_status(:deploy)
        end
      end
    end

    def handle_env_deploy
      config_data = FileAccess.new(:config)
      config_data.write_local unless config_data.local?
      secret_data = FileAccess.new(:secret)
      secret_data.write_local unless secret_data.local?
      perform_with_status { `kubectl apply -f #{File.expand_path(output_dir)}/#{Kubert.config_file_name} --record` }
      perform_with_status { `kubectl apply -f #{File.expand_path(output_dir)}/#{Kubert.secret_file_name} --record` }
      yield
      secret_data.clean_local unless secret_data.local?
      config_data.clean_local unless config_data.local?
    end

    def compilation
      @compilation ||= KY::API.compile(options[:configmap_path], options[:secrets_path], options[:output_dir], options_with_defaults)
    end

    private

    def confirm(action)
      unless options[:skip_confirmation]
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