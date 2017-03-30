require_relative '../kubert'
require 'thor'
module Kubert
  class Cli < Thor

    `hash kubectl 2>/dev/null;`
    unless $?.success?
      puts "Please install kubectl prior to kubert usage"
      exit $?.to_i
    end

    desc "list pod_type", "Display a list of one type of Pod, only Running by default"
    def list(pod_type, status=:running)
      puts Pods.list(pod_type, status)
    end

    desc "context", "Print current kubectl current context"
    def context
      puts Kubert.context
    end

    if Kubert.console_command.first == "rails"
      desc "sandbox", "Connect to a Rails console in sandbox that will wrap session in DB transaction and rollback when done"
      def sandbox
        execute(*Kubert.console_command, "--sandbox")
      end
    end

    if Kubert.console_command.any?
      desc "console", "Connect to a console on a task pod"
      def console
        execute(*Kubert.console_command)
      end
    end

    desc "execute command", "Connect to a task pod and run the specified command (with #{Kubert.command_prefix} prefix)"
    def execute(*command)
      Pods.execute(command)
    end

    desc "logs pod_type (status, default Running)", "Interleave and tail logs from all running pods of the specified type"
    def logs(pod_type, status= :running)
      Pods.logs(pod_type, status)
    end


    if Kubert.ky_active?
      desc "deploy", "Perform a deployment"
      method_option :namespace, type: :string, aliases: "-n"
      method_option :environment, type: :string, aliases: "-e"
      method_option :image_tag, type: :string, aliases: "-t"
      method_option :configmap_path, type: :string, aliases: "-c"
      method_option :secrets_path, type: :string, aliases: "-s"
      method_option :output_dir, type: :string, aliases: "-o"
      def deploy
        Deployment.perform(options)
      end

      desc "env", "Sub commands to manage secrets and configmap values"
      def env(*args)
        Kubert::EnvCli.start(args)
      end

      desc "rollback", "Rollback a deployment, reverse of a kubert deploy command with same flags"
      method_option :namespace, type: :string, aliases: "-n"
      method_option :environment, type: :string, aliases: "-e"
      method_option :image_tag, type: :string, aliases: "-t"
      method_option :configmap_path, type: :string, aliases: "-c"
      method_option :secrets_path, type: :string, aliases: "-s"
      method_option :output_dir, type: :string, aliases: "-o"
      def rollback
        Deployment.rollback(options)
      end
    end

    Kubert.contexts.each do |context_name, context_endpoint|
      desc context_name, "Use kubernetes #{context_endpoint} for kubectl commands"
      define_method(context_name) do
        puts `kubectl config use-context #{context_endpoint}`
      end
    end

  end
end