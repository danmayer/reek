require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'
require 'spec'
require 'spec/rake/spectask'

namespace 'test' do
  UNIT_TESTS = FileList['spec/reek/**/*_spec.rb']

  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = UNIT_TESTS
    t.spec_opts = ['--color']
    t.ruby_opts = ['-Ilib']
    t.rcov = false
  end

  Spec::Rake::SpecTask.new('quality') do |t|
    t.spec_files = FileList['quality/**/*_spec.rb']
    t.spec_opts = ['--color']
    t.ruby_opts = ['-Ilib']
    t.rcov = false
  end

  desc 'Runs all unit tests under RCov'
  Spec::Rake::SpecTask.new('rcov') do |t|
    t.spec_files = UNIT_TESTS
    t.rcov = true
    t.rcov_dir = 'build/coverage'
  end

  desc 'Checks all supported versions of Ruby'
  task :multiruby do
    sh "multiruby -S rake spec"
  end

  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format progress --color"
  end

  desc 'Runs all unit tests, acceptance tests and quality checks'
  task 'all' => ['test:spec', 'test:features', 'test:multiruby']
end

task 'clobber_rcov' => 'test:clobber_rcov'

desc 'synonym for test:spec'
task 'spec' => 'test:spec'

desc 'synonym for test:all'
task 'test' => 'test:all'
