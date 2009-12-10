require 'rake'
require 'rake/testtask'
require 'rbconfig'
 
desc 'Install the rack-auth-kerberos library (non-gem)'
task :install do
  dir = File.join(CONFIG['sitelibdir'], 'rack', 'auth')
  FileUtils.mkdir_p(dir) unless File.exists?(dir)
  file = 'lib/rack/auth/kerberos.rb'
  FileUtils.cp_r(file, dir, :verbose => true)
end
 
desc 'Build the gem'
task :gem do
  spec = eval(IO.read('rack-auth-kerberos.gemspec'))
  Gem::Builder.new(spec).build
end
 
desc 'Install the rack-auth-kerberos library as a gem'
task :install_gem => [:gem] do
   file = Dir["*.gem"].first
   sh "gem install #{file}"
end
 
desc 'Export the git archive to a .zip, .gz and .bz2 file in your home directory'
task :export, :output_file do |t, args|
  file = args[:output_file]
 
  sh "git archive --prefix #{file}/ --output #{ENV['HOME']}/#{file}.tar master"
 
  Dir.chdir(ENV['HOME']) do
    sh "gzip -f #{ENV['HOME']}/#{file}.tar"
  end
 
  sh "git archive --prefix #{file}/ --output #{ENV['HOME']}/#{file}.tar master"
 
  Dir.chdir(ENV['HOME']) do
    sh "bzip2 -f #{ENV['HOME']}/#{file}.tar"
  end
  
  sh "git archive --prefix #{file}/ --output #{ENV['HOME']}/#{file}.zip --format zip master"
 
  Dir.chdir(ENV['HOME']) do
    sh "unzip #{file}.zip"
    Dir.chdir(file) do
      sh "rake gem"
    end
  end
end
 
Rake::TestTask.new do |t|
   t.verbose = true
   t.warning = true
end
