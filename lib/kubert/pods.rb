module Kubert
  class Pods
    def self.list(pod_type, status)
      new.all(pod_type).status(status).names
    end

    def self.console
      new.console
    end

    attr_reader :project, :pods
    def initialize(project= ENV['PROJECT'] || "connect")
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

    def console
      pod = all('console').status(:running).pods.sample
      Open3.popen3("bash") do
        exec "kubectl exec -n #{pod.metadata.namespace} #{pod.metadata.name} -it bundle exec rails c"
      end
      puts "THIS WILL NEVER EXECUTE BECAUSE OF EXEC ABOVE"
    end


  end
end