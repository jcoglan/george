Gem::Specification.new do |s|
  s.name              = "george"
  s.version           = "0.1.0"
  s.summary           = "Makes you tea, helps you code"
  s.author            = "James Coglan"
  s.email             = "jcoglan@gmail.com"
  s.homepage          = "http://github.com/jcoglan/george"

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]
  s.require_paths     = %w[lib]
  s.executables       = %w[george]

  s.files = %w[README.rdoc] + Dir.glob("{bin,config,lib}/**/*")

  s.add_dependency "childprocess", "~> 0.3.0"
  s.add_dependency "oauth", "~> 0.4.0"
  s.add_dependency "twitter", "~> 4.0.0"
  s.add_dependency "rack"
end

