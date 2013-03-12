class George
  class Config

    def initialize(path)
      @data = YAML.load_file(path)
    end

    def method_missing(name)
      name = name.to_s
      return nil unless @data.include?(name)
      ENV['GEORGE_' + name.upcase] || @data[name]
    end

  end
end

