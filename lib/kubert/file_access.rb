module Kubert
  class FileAccess
    attr_reader :data
    def initialize(type, key)
      @type = type
      @key = key
      @s3_path = Kubert.public_send("s3_#{type}_path")
      @file_name = Kubert.public_send("#{type}_file_name")
      @data = read
    end

    def found
      data[:data].select {|k, _v| k == key }
    end

    def read
      YAML.load(file_read).with_indifferent_access
    end

    def set(value)
      if value.nil?
        data[:data].delete(key)
      else
        data[:data][key] = value
      end
      self
    end

    def get
      data[:data][key]
    end

    def write
      if s3_path
        s3_object.put(body: data.to_plain_yaml, content_encoding: 'application/octet-stream', content_type: "text/vnd.yaml", metadata: {author: `whoami`})
      else
        write_local
      end
    end

    def write_local
      File.write(local_path, data.to_plain_yaml)
    end

    private

    attr_reader :s3_path, :file_name, :type, :key

    def file_read
      return s3_object.get.body.read if s3_path
      File.read(local_path)
    end

    def local_path
      Kubert.ky_configuration["#{type}_path"] # options set & memoized elsewhere if needed
    end

    def s3_object
      @s3_object ||= begin
        require 'aws-sdk'
        s3 = Aws::S3::Resource.new
        match_data = s3_path.match(/\As3:\/\/(?<bucket>[^\/]+)\/(?<folder_path>\S+[^\/])\/?\z/)
        bucket = s3.bucket(match_data[:bucket])
        bucket.objects(prefix: "#{match_data[:folder_path]}/#{Kubert.current_namespace}/#{file_name}").first
      rescue LoadError
        puts "ERROR: s3_#{type}_path defined, but aws-sdk gem not available... it is not a hard dependency of kubert, but kubert requires it for s3 read/write if s3_#{type}_path defined"
      end
    end
  end
end