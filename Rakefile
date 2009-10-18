require 'rake'
require 'spec/rake/spectask'

desc "Run the tests"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.ruby_opts = [ '-rubygems' ]
  t.spec_opts = [ '--format specdoc' ]
  t.libs << 'lib'
  t.libs << 'spec'
end
task :default => :spec
