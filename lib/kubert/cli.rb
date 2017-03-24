require_relative '../kubert'
require 'thor'
require "irb"
module Kubert
  class Cli < Thor

    desc "list pod_type", "display a list of one type of Pod, only Ready by default"
    def list(pod_type, status=:running)
      puts Pods.list(pod_type, status)
    end

    desc "console", "Connect to a Rails console on a console pod"
    def console
      Pods.console
    end

  end
end