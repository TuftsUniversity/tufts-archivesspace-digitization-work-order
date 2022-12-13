# -*- encoding: utf-8 -*-
# stub: write_xlsx 0.85.3 ruby lib

Gem::Specification.new do |s|
  s.name = "write_xlsx".freeze
  s.version = "0.85.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hideo NAKAMURA".freeze]
  s.date = "2018-01-07"
  s.description = "write_xlsx is a gem to create a new file in the Excel 2007+ XLSX format.".freeze
  s.email = ["cxn03651@msj.biglobe.ne.jp".freeze]
  s.executables = ["extract_vba.rb".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze, "Changes".freeze]
  s.files = ["Changes".freeze, "LICENSE.txt".freeze, "README.md".freeze, "bin/extract_vba.rb".freeze]
  s.homepage = "http://github.com/cxn03651/write_xlsx#readme".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.8".freeze
  s.summary = "write_xlsx is a gem to create a new file in the Excel 2007+ XLSX format.".freeze

  s.installed_by_version = "2.6.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 1.0.0"])
      s.add_runtime_dependency(%q<zip-zip>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rubyzip>.freeze, [">= 1.0.0"])
      s.add_dependency(%q<zip-zip>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rubyzip>.freeze, [">= 1.0.0"])
    s.add_dependency(%q<zip-zip>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
