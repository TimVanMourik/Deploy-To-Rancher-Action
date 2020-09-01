# -*- encoding: utf-8 -*-
# stub: stub_env 1.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "stub_env".freeze
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Liam Bennett".freeze]
  s.date = "2015-08-20"
  s.description = "RSpec helper for stubbing ENV values".freeze
  s.email = ["liam@littleowllabs.com".freeze]
  s.homepage = "https://github.com/littleowllabs/stub_env".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Stub ENV values in RSpec tests".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>.freeze, [">= 2.0", "< 4.0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    else
      s.add_dependency(%q<rspec>.freeze, [">= 2.0", "< 4.0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, [">= 2.0", "< 4.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
