#
# Copyright (c) 2015-present, Parse, LLC.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require_relative 'Vendor/xctoolchain/Scripts/xctask/build_task'

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
starters_path = File.join(SCRIPT_PATH, 'ParseStarterProject')

ios_version = ENV.fetch('IOS_VERSION', '')
ios_device_model = ENV.fetch('IOS_DEVICE_MODEL', '')
tvos_version = ENV.fetch('TV_OS_VERSION', '')
tv_device_model = ENV.fetch('TV_DEVICE_MODEL', '')
watchos_version = ENV.fetch('WATCH_OS_VERSION', '')
watch_device_model = ENV.fetch('WATCH_DEVICE_MODEL', '')

puts "IOS_VERSION: #{ios_version}"
puts "IOS_DEVICE_MODEL: #{ios_device_model}"
puts "TV_OS_VERSION: #{tvos_version}"
puts "TV_DEVICE_MODEL: #{tv_device_model}"
puts "WATCH_OS_VERSION: #{watchos_version}"
puts "WATCH_DEVICE_MODEL: #{watch_device_model}"

ios_simulator = "platform=\"iOS Simulator\",name=\"#{ios_device_model}\",OS=\"#{ios_version}\""
tvos_simulator = "platform=\"tvOS Simulator\",name=\"#{tv_device_model}\",OS=\"#{tvos_version}\""
watchos_simulator = "platform=\"watchOS Simulator\",name=\"#{watch_device_model}\",OS=\"#{watchos_version}\""

build_action = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD];

module Constants
  require 'plist'

  PARSE_CONSTANT_PATH = File.join(SCRIPT_PATH, 'Parse', 'Parse', 'Source/PFConstants.h')
  PLISTS = [
    File.join(SCRIPT_PATH, 'Parse', 'Parse', 'Resources', 'Parse-iOS.Info.plist'),
    File.join(SCRIPT_PATH, 'Parse', 'Parse', 'Resources', 'Parse-OSX.Info.plist'),
    File.join(SCRIPT_PATH, 'Parse', 'Parse', 'Resources', 'Parse-watchOS.Info.plist'),
    File.join(SCRIPT_PATH, 'Parse', 'Parse', 'Resources', 'Parse-tvOS.Info.plist'),
    File.join(SCRIPT_PATH, 'ParseLiveQuery', 'ParseLiveQuery', 'Resources', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseLiveQuery', 'ParseLiveQuery-tvOS', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseLiveQuery', 'ParseLiveQuery-watchOS', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'iOS', 'ParseStarterProject', 'Resources', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'iOS', 'ParseStarterProject-Swift', 'Resources', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'OSX', 'ParseOSXStarterProject', 'Resources', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'OSX', 'ParseOSXStarterProject-Swift', 'Resources', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'tvOS', 'ParseStarterProject-Swift', 'ParseStarter', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'watchOS', 'ParseStarterProject-Swift', 'ParseStarter', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'watchOS', 'ParseStarterProject-Swift', 'ParseStarter Extension', 'Info.plist'),
    File.join(SCRIPT_PATH, 'ParseStarterProject', 'watchOS', 'ParseStarterProject-Swift', 'Resources', 'Info.plist'),
  ]

  def self.current_version
    constants_file = File.open(PARSE_CONSTANT_PATH, 'r').read
    matches = constants_file.match(/(.*PARSE_VERSION\s*@")(.*)(")/)
    matches[2] # Return the second match, which is the version itself
  end

  def self.update_version(version)
    constants_file = File.open(PARSE_CONSTANT_PATH, 'r+')
    constants = constants_file.read
    constants.gsub!(/(.*PARSE_VERSION\s*@")(.*)(")/, "\\1#{version}\\3")

    constants_file.seek(0)
    constants_file.write(constants)

    PLISTS.each do |plist|
      update_info_plist_version(plist, version)
    end
  end

  def self.update_info_plist_version(plist_path, version)
    info_plist = Plist.parse_xml(plist_path)
    info_plist['CFBundleShortVersionString'] = version
    info_plist['CFBundleVersion'] = version
    File.open(plist_path, 'w') { |f| f.write(info_plist.to_plist) }
  end
end

namespace :package do
  task :set_version, [:version] do |_, args|
    version = args[:version] || Constants.current_version
    Constants.update_version(version)
  end
end

namespace :build do
  namespace :ios_starters do
    task :all do
      Rake::Task['build:ios_starters:objc'].invoke
      Rake::Task['build:ios_starters:swift'].invoke
    end

    task :objc do
      puts 'Running iOS ObjC Starter Project'
      puts "IOS_VERSION: #{ios_version}"
      puts "IOS_DEVICE_MODEL: #{ios_device_model}"
      project = 'ParseStarterProject'
      ios_starters_path = File.join(starters_path, 'iOS', project)
      task = XCTask::BuildTask.new do |t|
        t.directory = ios_starters_path
        t.project = "#{project}.xcodeproj"
        t.scheme = project
        t.configuration = 'Debug'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'iOS Starter Project Failed!'
        exit(1)
      end
    end

    task :swift do
      puts 'Running iOS Swift Starter Project'
      puts "IOS_VERSION: #{ios_version}"
      puts "IOS_DEVICE_MODEL: #{ios_device_model}"
      project = 'ParseStarterProject-Swift'
      ios_starters_path = File.join(starters_path, 'iOS', project)
      task = XCTask::BuildTask.new do |t|
        t.directory = ios_starters_path
        t.project = "#{project}.xcodeproj"
        t.scheme = project
        t.configuration = 'Debug'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'iOS Starter Project Failed!'
        exit(1)
      end
    end
  end

  namespace :macos_starters do
    task :all do
      Rake::Task['build:macos_starters:objc'].invoke
      Rake::Task['build:macos_starters:swift'].invoke
    end

    task :objc do
      puts 'Running macOS ObjC Starter Project'
      macos_starter_folder = File.join(starters_path, 'OSX', 'ParseOSXStarterProject')
      task = XCTask::BuildTask.new do |t|
        t.directory = macos_starter_folder
        t.project = 'ParseOSXStarterProject.xcodeproj'
        t.scheme = 'ParseOSXStarterProject'
        t.configuration = 'Debug'
        t.sdk = 'macosx'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'macOS Starter Project Failed!'
        exit(1)
      end
    end

    task :swift do
      puts 'Running macOS Swift Starter Project'
      macos_starter_folder = File.join(starters_path, 'OSX', 'ParseOSXStarterProject-Swift')
      task = XCTask::BuildTask.new do |t|
        t.directory = macos_starter_folder
        t.project = 'ParseOSXStarterProject-Swift.xcodeproj'
        t.scheme = 'ParseOSXStarterProject-Swift'
        t.configuration = 'Debug'
        t.sdk = 'macosx'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'macOS Starter Project Failed!'
        exit(1)
      end
    end
  end

  namespace :tvos_starters do
    task :all do
      # TODO: tvos objc starter
      # Rake::Task['build:tvos_starters:objc'].invoke
      Rake::Task['build:tvos_starters:swift'].invoke
    end

    task :swift do
      puts 'Running tvOS Swift Starter Project'
      puts "TV_OS_VERSION: #{tvos_version}"
      puts "TV_DEVICE_MODEL: #{tv_device_model}"
      tvos_starter_folder = File.join(starters_path, 'tvOS', 'ParseStarterProject-Swift')
      task = XCTask::BuildTask.new do |t|
        t.directory = tvos_starter_folder
        t.project = 'ParseStarter-Swift.xcodeproj'
        t.scheme = 'ParseStarter'
        t.configuration = 'Debug'
        t.destinations = [tvos_simulator]
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'tvOS Starter Project Failed!'
        exit(1)
      end
    end
  end

  namespace :watchos_starters do
    task :all do
      # TODO: watchos objc starter
      # Rake::Task['build:watchos_starters:objc'].invoke
      Rake::Task['build:watchos_starters:swift'].invoke
    end

    task :swift do
      puts 'Running watchOS Swift Starter Project'
      puts "WATCH_OS_VERSION: #{watchos_version}"
      puts "WATCH_DEVICE_MODEL: #{watch_device_model}"
      watchos_starter_folder = File.join(starters_path, 'watchOS', 'ParseStarterProject-Swift')
      task = XCTask::BuildTask.new do |t|
        t.directory = watchos_starter_folder
        t.project = 'ParseStarter-Swift.xcodeproj'
        t.scheme = 'ParseStarter'
        t.configuration = 'Debug'
        t.destinations = [watchos_simulator]
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'watchOS Starter Project Failed!'
        exit(1)
      end
    end
  end

  namespace :live_query_starters do
    task :all do
      Rake::Task['build:live_query_starters:objc'].invoke
      Rake::Task['build:live_query_starters:swift'].invoke
    end

    task :objc do
      puts 'Running Live Query macOS ObjC Starter Project'
      live_query_starter_folder = File.join(SCRIPT_PATH, 'ParseLiveQuery', 'Examples')
      task = XCTask::BuildTask.new do |t|
        t.directory = live_query_starter_folder
        t.project = 'LiveQueryDemo-ObjC.xcodeproj'
        t.scheme = 'LiveQueryDemo-ObjC'
        t.configuration = 'Debug'
        t.sdk = 'macosx'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'Live Query ObjC Starter Project Failed!'
        exit(1)
      end
    end

    task :swift do
      puts 'Running Live Query macOS Swift Starter Project'
      live_query_starter_folder = File.join(SCRIPT_PATH, 'ParseLiveQuery', 'Examples')
      task = XCTask::BuildTask.new do |t|
        t.directory = live_query_starter_folder
        t.project = 'LiveQueryDemo.xcodeproj'
        t.scheme = 'LiveQueryDemo'
        t.configuration = 'Debug'
        t.sdk = 'macosx'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'Live Query Swift Starter Project Failed!'
        exit(1)
      end
    end
  end

  desc 'Build all starters'
  task :starters do
    Rake::Task['build:tvos_starters:all'].invoke
    Rake::Task['build:watchos_starters:all'].invoke
    Rake::Task['build:ios_starters:all'].invoke
    Rake::Task['build:macos_starters:all'].invoke
    Rake::Task['build:live_query_starters:all'].invoke
  end
end

namespace :test do
  desc 'Run iOS Tests'
  task :ios do |_, args|
    puts 'Running iOS Tests'
    puts "IOS_VERSION: #{ios_version}"
    puts "IOS_DEVICE_MODEL: #{ios_device_model}"
    task = XCTask::BuildTask.new do |t|
      t.directory = SCRIPT_PATH
      t.workspace = 'Parse.xcworkspace'
      t.scheme = 'Parse-iOS'
      t.sdk = 'iphonesimulator'
      t.destinations = [ios_simulator]
      t.configuration = 'Debug -enableCodeCoverage YES'
      t.actions = [XCTask::BuildAction::TEST]
      t.formatter = XCTask::BuildFormatter::XCPRETTY
    end
    unless task.execute
      puts 'iOS Tests Failed!'
      exit(1)
    end
  end

  desc 'Run macOS Tests'
  task :macos do |_, args|
    puts 'Running macOS Tests'
    task = XCTask::BuildTask.new do |t|
      t.directory = SCRIPT_PATH
      t.workspace = 'Parse.xcworkspace'
      t.scheme = 'Parse-macOS'
      t.sdk = 'macosx'
      t.configuration = 'Debug -enableCodeCoverage YES'
      t.actions = [XCTask::BuildAction::TEST]
      t.formatter = XCTask::BuildFormatter::XCPRETTY
    end
    unless task.execute
      puts 'macOS Tests Failed!'
      exit(1)
    end
  end

  namespace :parse_live_query do
    task :all do
      Rake::Task['test:parse_live_query:ios'].invoke
      Rake::Task['test:parse_live_query:tvos'].invoke
      Rake::Task['test:parse_live_query:watchos'].invoke
      Rake::Task['test:parse_live_query:osx'].invoke
    end

    task :ios do
      puts 'Running ParseLiveQuery iOS Tests'
      puts "IOS_VERSION: #{ios_version}"
      puts "IOS_DEVICE_MODEL: #{ios_device_model}"
      task = XCTask::BuildTask.new do |t|
        t.directory = SCRIPT_PATH
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-iOS'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'Failed to build ParseLiveQuery'
        exit(1)
      end
    end

    task :tvos do
      puts 'Running ParseLiveQuery tvOS Tests'
      puts "TV_OS_VERSION: #{tvos_version}"
      puts "TV_DEVICE_MODEL: #{tv_device_model}"
      task = XCTask::BuildTask.new do |t|
        t.directory = SCRIPT_PATH
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-tvOS'
        t.destinations = [tvos_simulator]
        t.configuration = 'Debug'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'Failed to build ParseLiveQuery-tvOS.'
        exit(1)
      end
    end

    task :watchos do
      puts 'Running ParseLiveQuery watchOS Tests'
      puts "WATCH_OS_VERSION: #{watchos_version}"
      puts "WATCH_DEVICE_MODEL: #{watch_device_model}"
      task = XCTask::BuildTask.new do |t|
        t.directory = SCRIPT_PATH
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-watchOS'
        t.destinations = [watchos_simulator]
        t.configuration = 'Debug'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'Failed to build ParseLiveQuery-watchOS.'
        exit(1)
      end
    end
    
    task :osx do
      puts 'Running ParseLiveQuery macOS Tests'
      task = XCTask::BuildTask.new do |t|
        t.directory = SCRIPT_PATH
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-OSX'
        t.configuration = 'Debug'
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
        puts 'Failed to build ParseLiveQuery-OSX.'
        exit(1)
      end
    end
  end
end
