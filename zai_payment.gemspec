# frozen_string_literal: true

require_relative 'lib/zai_payment/version'

Gem::Specification.new do |spec|
  spec.name = 'zai_payment'
  spec.version = ZaiPayment::VERSION
  spec.authors = ['Eddy Jaga']
  spec.email = ['eddy.jaga@sentia.com.au']

  spec.summary = 'Ruby gem for Zai payment integration'
  spec.description = 'A Ruby gem for integrating with Zai payment platform APIs.'
  spec.homepage = 'https://www.sentia.com.au'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Sentia/zai-payment'
  spec.metadata['changelog_uri'] = 'https://github.com/Sentia/zai-payment/blob/main/changelog.md'
  spec.metadata['code_of_conduct_uri'] = 'https://github.com/Sentia/zai-payment/blob/main/code_of_conduct.md'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['documentation_uri'] = 'https://github.com/Sentia/zai-payment#readme'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'base64', '~> 0.3.0'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'openssl', '~> 3.3'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
