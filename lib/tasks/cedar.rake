require 'yaml'
require 'tmpdir'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'xcode_config'))

@thrust_config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'thrust.yml'))

@spec_config = @thrust_config['specs']

task :default => [:trim, :specs]

desc 'Trim whitespace'
task :trim do
  XcodeConfig.system_or_exit %Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $2}' | grep -e '.*\.[cmh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;']
end

desc 'Clean all targets'
task :clean do
  XcodeConfig.system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration 'AdHoc' -sdk iphoneos clean", XcodeConfig.output_file("clean")
  XcodeConfig.system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration 'Debug' -sdk iphonesimulator clean", XcodeConfig.output_file("clean")
  XcodeConfig.system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -alltargets -configuration 'Release' -sdk iphonesimulator clean", XcodeConfig.output_file("clean")
end

desc 'Build specs'
task :build_specs do
  XcodeConfig.kill_simulator
  XcodeConfig.system_or_exit "xcodebuild -project #{@thrust_config['project_name']}.xcodeproj -target #{@spec_config['target']} -configuration #{@spec_config['configuration']} -sdk iphonesimulator build", XcodeConfig.output_file("specs")
end

desc 'Run specs'
task :specs => :build_specs do
  binary = @spec_config['binary']
  case binary
    when /waxim$/
      break
      XcodeConfig.grep_cmd_for_failure(%Q[#{binary} -s #{@spec_config['sdk']} -f iphone -e CFFIXED_USER_HOME=#{Dir.tmpdir} -e CEDAR_HEADLESS_SPECS=1 -e CEDAR_REPORTER_CLASS=CDRDefaultReporter #{File.join(XcodeConfig.sim_dir, "#{@spec_config['target']}.app")}])
    when /ios-sim$/
      break
      XcodeConfig.grep_cmd_for_failure(%Q[#{binary} launch #{File.join(XcodeConfig.sim_dir, "#{@spec_config['target']}.app")} --sdk #{@spec_config['sdk']} --family iphone --retina --tall --setenv CFFIXED_USER_HOME=#{Dir.tmpdir} --setenv CEDAR_HEADLESS_SPECS=1 --setenv CEDAR_REPORTER_CLASS=CDRDefaultReporter])
  end
end