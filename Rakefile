require "rubygems"
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require "rake/gempackagetask"
require 'spec/rake/spectask'

PKG_VERSION = "0.4.4"
PKG_NAME = "rbook"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
RUBYFORGE_PROJECT = 'rbook'
RUBYFORGE_USER = 'yob'

CLEAN.include "**/.*.sw*"

desc "Default Task"
task :default => [ :test ]

desc "Cruise Control Tasks"
task :cruise => [ :spec, :spec_report, :doc ]

# Run all tests
desc "Run all test"
task :test => [ :test_units ]

# Run the unit tests
desc "Run all unit tests"
Rake::TestTask.new("test_units") { |t|
  t.pattern = 'test/unit/**/*_test.rb'
  t.verbose = true
  t.warning = true
}

# run all rspecs
desc "Run all rspec files"
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_files = FileList['specs/**/*.rb']
  t.rcov = true
  t.rcov_dir = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + "/rcov"
  t.rcov_opts = ["--exclude","spec.*\.rb"]
end

# generate specdocs
desc "Generate Specdocs"
Spec::Rake::SpecTask.new("specdocs") do |t|
  t.spec_files = FileList['specs/**/*.rb']
  t.spec_opts = ["--format", "rdoc"]
  t.out = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/specdoc.rd'
end

# generate failing spec report
desc "Generate failing spec report"
Spec::Rake::SpecTask.new("spec_report") do |t|
  t.spec_files = FileList['specs/**/*.rb']
  t.spec_opts = ["--format", "html", "--diff"]
  t.out = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/spec_report.html'
  t.fail_on_error = false
end

# Genereate the RDoc documentation
desc "Create documentation"
Rake::RDocTask.new("doc") do |rdoc|
  rdoc.title = "RBook"
  rdoc.rdoc_dir = (ENV['CC_BUILD_ARTIFACTS'] || 'doc') + '/rdoc'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('COPYING')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << "--inline-source"
end

spec = Gem::Specification.new do |spec|
	spec.name = PKG_NAME
	spec.version = PKG_VERSION
	spec.platform = Gem::Platform::RUBY
	spec.summary = "A collection of classes and modules for working with bibliographic data"
	spec.files =  Dir.glob("{examples,lib,test}/**/**/*") +
                      ["Rakefile"]
  
  spec.require_path = "lib"
  spec.bindir = "bin"
  spec.test_files = Dir[ "test/test_*.rb" ]
	spec.has_rdoc = true
	spec.extra_rdoc_files = %w{README COPYING LICENSE}
	spec.rdoc_options << '--title' << 'rbook Documentation' <<
	                     '--main'  << 'README' << '-q'
  spec.add_dependency('scrapi', '>= 1.2.0')
  spec.author = "James Healy"
	spec.email = "jimmy@deefa.com"
	spec.rubyforge_project = "rbook"
	spec.homepage = "http://rbook.rubyforge.org/"
	spec.description = <<END_DESC
  rbook is a collection of classes and modules for 
  working with bibliographic data. It currently 
  supports converting and validating isbns, and converting
  to and from both ONIX and BISAC
END_DESC
end

desc "Generate a gem for rbook"
Rake::GemPackageTask.new(spec) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end

desc "Report code statistics (KLOCs, etc) from the application"
task :stats do
  require 'vendor/code_statistics'
  #dirs = [["Library", "lib"],["Functional tests", "test/functional"],["Unit tests", "test/unit"]]
  dirs = [["Library", "lib"],["Unit tests", "test/unit"]]
  CodeStatistics.new(*dirs).to_s
end


# Release files to Rubyforge. 
# The code for this task provided by Florian Gross.
desc "Publish the release files to RubyForge." 

task :publish => [:package] do

  files = ['gem', 'tgz', 'zip'].map { |ext| "pkg/#{PKG_NAME}-#{PKG_VERSION}.#{ext}" }

  if RUBYFORGE_PROJECT then
    require 'net/http'
    require 'open-uri'

    changes = ''
    if File.exist?('doc/RELEASES') then
      changes_re = /^== \s+ Version \s+ #{Regexp.quote(Version)} \s*
                    (.+?) (?:==|\Z)/mx
      changes = File.read('doc/RELEASES')[changes_re, 1] || ''
    end

    project_uri = "http://rubyforge.org/projects/#{RUBYFORGE_PROJECT}/"
    project_data = open(project_uri) { |data| data.read }
    group_id = project_data[/[?&]group_id=(\d+)/, 1]
    raise "Couldn't get group id" unless group_id

    print "#{RUBYFORGE_USER}@rubyforge.org's password: "
    password = STDIN.gets.chomp

    login_response = Net::HTTP.start('rubyforge.org', 80) do |http|
      data = [
        "login=1",
        "form_loginname=#{RUBYFORGE_USER}",
        "form_pw=#{password}"
      ].join("&")
      http.post('/account/login.php', data)
    end
    puts login_response
    cookie = login_response['set-cookie']
    raise 'Login failed' unless cookie
    headers = { 'Cookie' => cookie }

    release_uri = "http://rubyforge.org/frs/admin/?group_id=#{group_id}"
    release_data = open(release_uri, headers) { |data| data.read }
    package_id = release_data[/[?&]package_id=(\d+)/, 1]
    raise "Couldn't get package id" unless package_id

    first_file = true
    release_id = ""

    files.each do |filename|
      basename = File.basename(filename)
      file_ext = File.extname(filename)
      file_data = File.open(filename, "rb") { |file| file.read }

      puts "Releasing #{basename}..."

      release_response = Net::HTTP.start('rubyforge.org', 80) do |http|
        release_date = Time.now.strftime('%Y-%m-%d %H:%M')
        type_map = {
          '.zip'    => '3000',
          '.tgz'    => '3110',
          '.gz'     => '3110',
          '.gem'    => '1400',
          '.md5sum' => '8100'
        }; type_map.default = '9999'
        type = type_map[file_ext]
        boundary = 'rubyqMY6QN9bp6e4kS21H4y0zxcvoor'

        query_hash = if first_file then
          {
            'group_id' => group_id,
            'package_id' => package_id,
            'release_name' => PKG_VERSION,
            'release_date' => release_date,
            'type_id' => type,
            'processor_id' => '8000', # Any
            'release_notes' => '',
            'release_changes' => changes,
            'preformatted' => '1',
            'submit' => '1'
          }
        else
          {
            'group_id' => group_id,
            'release_id' => release_id,
            'package_id' => package_id,
            'step2' => '1',
            'type_id' => type,
            'processor_id' => '8000', # Any
            'submit' => 'Add This File'
          }
        end

        query = '?' + query_hash.map do |(name, value)|
          [name, URI.encode(value)].join('=')
        end.join('&')

        data = [
          "--" + boundary,
          "Content-Disposition: form-data; name=\"userfile\"; filename=\"#{basename}\"",
          "Content-Type: application/octet-stream",
          "Content-Transfer-Encoding: binary",
          "", file_data, ""
          ].join("\x0D\x0A")

        release_headers = headers.merge(
          'Content-Type' => "multipart/form-data; boundary=#{boundary}"
        )

        target = first_file ? '/frs/admin/qrs.php' : '/frs/admin/editrelease.php'
        http.post(target + query, data, release_headers)
      end

      if first_file then
        puts release_response.body
        release_id = release_response.body[/release_id=(\d+)/, 1]
        raise("Couldn't get release id") unless release_id
      end

      first_file = false
    end
  end

end 
