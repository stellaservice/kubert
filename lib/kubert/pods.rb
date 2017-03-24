module Kubert
  class Pods
    def self.list(pod_type, status)
      new.all(pod_type).status(status).names
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
      @pods = pods.select {|pod| pod.status.phase.downcase == pod_status.downcase }
      self
    end

    def names
      pods.map(&:metadata).map(&:name)
    end


  end
end