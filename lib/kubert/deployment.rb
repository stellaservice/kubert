module Kubert
  class Deployment
    def self.perform
      new.perform
    end

    def self.rollback
      new.rollback
    end

    attr_reader :project_name, :deployments
    def initialize(project_name= Kubert.configuration[:project_name])
      @project_name = project_name
      @deployments = []
    end

    def rollback
    end

    def perform
    end
  end
end