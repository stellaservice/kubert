require_relative '../kubert'
require 'thor'
require "irb"
module Kubert
  class Cli < Thor

    desc "list pod_type", "display a list of one type of Pod, only Ready by default"
    def list(pod_type, status=:running)
      puts Pods.list(pod_type, status)
    end

    desc "context", "Print current kubectl current context"
    def context
      puts Kubert.kube_config.contexts.select {|c| Kubert.kube_config.context.api_endpoint.match(c) }
    end

    desc "sandbox", "Connect to a Rails console in sandbox that will wrap session in DB transaction and rollback when done"
    def sandbox
      execute("rails", "console", "--sandbox")
    end

    desc "console", "Connect to a Rails console on a console pod"
    def console
      execute("rails", "console")
    end

    desc "execute command", "Connect to a pod run the specified command (with bundle exec prefix)"
    def execute(*command)
      Pods.execute(command)
    end

    desc "deploy", "Perform a deployment"
    def deploy
      Deployment.perform
    end

    desc "rollback", "Connect to a pod run the specified command (with bundle exec prefix)"
    def rollback
      Deployment.rollback
    end

    Kubert.contexts.each do |context_name, context_endpoint|
      desc context_name, "Use kubernetes #{context_endpoint} for kubectl commands"
      define_method(context_name) do
        puts `kubectl config use-context #{context_endpoint}`
      end
    end

  end
end