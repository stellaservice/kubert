require_relative '../kubert'
require 'thor'
module Kubert
  class Cli < Thor

    desc "list pod_type", "display a list of one type of Pod, only Ready by default"
    def list(pod_type, status='Running')
      puts Pods.list(pod_type, status)
    end
  end
end