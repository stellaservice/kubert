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

    def self.logs(pod_type, status)
      new.all(pod_type).status(status).logs
    end

    attr_reader :project_name, :pods
    def initialize(project_name= Kubert.configuration[:project_name])
      @project_name = project_name
      @pods = []
    end

    def all(pod_type)
      @pods = Kubert.client.get_pods(label_selector: "app=#{project_name}-#{pod_type}")
      self
    end

    def status(pod_status)
      @pods = pods.select {|pod| pod.status.phase.downcase == pod_status.to_s }
      self
    end

    def names
      pods.map(&:metadata).map(&:name)
    end

    def execute(command, pod_type=Kubert.task_pod)
      pod = all(pod_type).status(:running).pods.sample
      exec_command = "kubectl exec -n #{pod.metadata.namespace} #{pod.metadata.name} -it #{Kubert.command_prefix} #{command.join(' ')}"
      puts "Executing command: \n#{exec_command}"
      Open3.popen3("bash") do
        exec exec_command
      end
      puts "THIS WILL NEVER EXECUTE BECAUSE OF EXEC ABOVE"
    end

    def logs
      fibers = names.map.with_index do |pod_name, i|
        puts "logging #{pod_name}:"
        watcher = Kubert.client.watch_pod_log(pod_name, pods.first.metadata.namespace)
        pod_name = names[i]
        log_enum = watcher.to_enum
        Fiber.new do
          loop do
            Fiber.yield(puts "#{pod_name} |> #{log_enum.next}")
          end
        end
      end
      while fibers.all?(&:alive?) do
        fibers.shuffle.each(&:resume)
      end
    end

  end
end