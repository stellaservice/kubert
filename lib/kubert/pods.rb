module Kubert
  class Pods
    def self.list(pod_type, status)
      new.all(pod_type).status(status).names
    end

    def self.console
      new.console
    end

    def self.execute(command)
      new.execute(command)
    end

    attr_reader :project, :pods
    def initialize(project= ENV['KUBERT_PROJECT'] || "connect")
      @project = project
      @pods = []
    end

    def all(pod_type)
      @pods = Kubert.client.get_pods(label_selector: "app=#{project}-#{pod_type}")
      self
    end

    def status(pod_status)
      @pods = pods.select {|pod| pod.status.phase.downcase == pod_status.to_s }
      self
    end

    def names
      pods.map(&:metadata).map(&:name)
    end

    def execute(command)
      pod = all('console').status(:running).pods.sample
      exec_command = "kubectl exec -n #{pod.metadata.namespace} #{pod.metadata.name} -it bundle exec #{command.join(' ')}"
      puts "Executing command: \n#{exec_command}"
      Open3.popen3("bash") do
        exec exec_command
      end
      puts "THIS WILL NEVER EXECUTE BECAUSE OF EXEC ABOVE"
    end

  end
end