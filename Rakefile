#
# Copyright (c) 2015-present, Parse, LLC.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require_relative 'Vendor/xctoolchain/Scripts/xctask/build_task'
require_relative 'Vendor/xctoolchain/Scripts/xctask/build_framework_task'

script_folder = File.expand_path(File.dirname(__FILE__))
build_folder = File.join(script_folder, 'build')
ios_simulator = 'platform="iOS Simulator",name="iPhone 14"'
tvos_simulator = 'platform="tvOS Simulator",name="Apple TV"'
watchos_simulator = 'platform="watchOS Simulator",name="Apple Watch Series 8 (45mm)"'

namespace :build do
  desc 'Build iOS framework.'
  task :ios do
    task = XCTask::BuildFrameworkTask.new do |t|
      t.directory = script_folder
      t.build_directory = build_folder
      t.framework_type = XCTask::FrameworkType::IOS
      t.framework_name = 'Parse.framework'
      t.workspace = 'Parse.xcworkspace'
      t.scheme = 'Parse-iOS'
      t.configuration = 'Release'
    end
    result = task.execute
    unless result
      puts 'Failed to build iOS Framework.'
      exit(1)
    end
  end

  desc 'Build watchOS framework.'
  task :watchos do
    task = XCTask::BuildFrameworkTask.new do |t|
      t.directory = script_folder
      t.build_directory = build_folder
      t.framework_type = XCTask::FrameworkType::WATCHOS
      t.framework_name = 'Parse.framework'
      t.workspace = 'Parse.xcworkspace'
      t.scheme = 'Parse-watchOS'
      t.configuration = 'Release'
    end
    result = task.execute
    unless result
      puts 'Failed to build watchOS Framework.'
      exit(1)
    end
  end

  desc 'Build macOS framework.'
  task :macos do
    task = XCTask::BuildFrameworkTask.new do |t|
      t.directory = script_folder
      t.build_directory = build_folder
      t.framework_type = XCTask::FrameworkType::OSX
      t.framework_name = 'Parse.framework'
      t.workspace = 'Parse.xcworkspace'
      t.scheme = 'Parse-macOS'
      t.configuration = 'Release'
    end
    result = task.execute
    unless result
      puts 'Failed to build macOS Framework.'
      exit(1)
    end
  end

  desc 'Build tvOS framework.'
  task :tvos do
    task = XCTask::BuildFrameworkTask.new do |t|
      t.directory = script_folder
      t.build_directory = build_folder
      t.framework_type = XCTask::FrameworkType::TVOS
      t.framework_name = 'Parse.framework'
      t.workspace = 'Parse.xcworkspace'
      t.scheme = 'Parse-tvOS'
      t.configuration = 'Release'
    end
    result = task.execute
    unless result
      puts 'Failed to build tvOS Framework.'
      exit(1)
    end
  end

  namespace :parse_live_query do
    desc 'Build iOS LiveQuery framework.'
    task :ios do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'iOS')
        t.framework_type = XCTask::FrameworkType::IOS
        t.framework_name = 'ParseLiveQuery.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-iOS'
        t.configuration = 'Release'
      end
      result = task.execute
      unless result
        puts 'Failed to build iOS LiveQuery Framework.'
        exit(1)
      end
    end

    desc 'Build macOS LiveQuery framework.'
    task :macos do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'macOS')
        t.framework_type = XCTask::FrameworkType::OSX
        t.framework_name = 'ParseLiveQuery.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-OSX'
        t.configuration = 'Release'
      end
      result = task.execute
      unless result
        puts 'Failed to build macOS LiveQuery Framework.'
        exit(1)
      end
    end

    desc 'Build watchOS LiveQuery framework.'
    task :watchos do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'watchOS')
        t.framework_type = XCTask::FrameworkType::WATCHOS
        t.framework_name = 'ParseLiveQuery_watchOS.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-watchOS'
        t.configuration = 'Release'
      end
      result = task.execute
      unless result
        puts 'Failed to build watchOS LiveQuery Framework.'
        exit(1)
      end
    end

    desc 'Build tvOS LiveQuery framework.'
    task :tvos do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'tvOS')
        t.framework_type = XCTask::FrameworkType::TVOS
        t.framework_name = 'ParseLiveQuery_tvOS.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseLiveQuery-tvOS'
        t.configuration = 'Release'
      end
      result = task.execute
      unless result
        puts 'Failed to build tvOS LiveQuery Framework.'
        exit(1)
      end
    end
  end

  namespace :facebook_utils do
    desc 'Build iOS FacebookUtils framework.'
    task :ios do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'iOS')
        t.framework_type = XCTask::FrameworkType::IOS
        t.framework_name = 'ParseFacebookUtilsV4.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseFacebookUtilsV4-iOS'
        t.configuration = 'Release'
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS FacebookUtils Framework.'
        exit(1)
      end
    end

    desc 'Build tvOS FacebookUtils framework.'
    task :tvos do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'tvOS')
        t.framework_type = XCTask::FrameworkType::TVOS
        t.framework_name = 'ParseFacebookUtilsV4.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseFacebookUtilsV4-tvOS'
        t.configuration = 'Release'
      end
      result = task.execute
      unless result
        puts 'Failed to build tvOS FacebookUtils Framework.'
        exit(1)
      end
    end
  end

  namespace :twitter_utils do
    desc 'Build iOS TwitterUtils framework.'
    task :ios do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'iOS')
        t.framework_type = XCTask::FrameworkType::IOS
        t.framework_name = 'ParseTwitterUtils.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseTwitterUtils-iOS'
        t.configuration = 'Release'
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS TwitterUtils Framework.'
        exit(1)
      end
    end
  end

  namespace :parseui do
    task :framework do
      task = XCTask::BuildFrameworkTask.new do |t|
        t.directory = script_folder
        t.build_directory = File.join(build_folder, 'iOS')
        t.framework_type = XCTask::FrameworkType::IOS
        t.framework_name = 'ParseUI.framework'
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseUI'
        t.configuration = 'Release'
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseUI'
        exit(1)
      end
    end

    task :demo_objc do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseUIDemo'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug'
        t.additional_options = { "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS" => "YES",
                                 "GCC_GENERATE_TEST_COVERAGE_FILES" => "YES" }

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseUI Demo.'
        exit(1)
      end
    end

    task :demo_swift do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'
        t.scheme = 'ParseUIDemo-Swift'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug'
        t.additional_options = { "GCC_INSTRUMENT_PROGRAM_FLOW_ARCS" => "YES",
                                 "GCC_GENERATE_TEST_COVERAGE_FILES" => "YES" }

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS ParseUI Swift Demo.'
        exit(1)
      end
    end
  end
end

namespace :package do
  desc 'Build all frameworks and starters'
  task :release do |_|
    Rake::Task['package:frameworks'].invoke
  end

  desc 'Build all frameworks'
  task :frameworks do |_|
    Rake::Task['build:ios'].invoke
    Rake::Task['build:macos'].invoke
    Rake::Task['build:tvos'].invoke
    Rake::Task['build:watchos'].invoke
    Rake::Task['build:facebook_utils:ios'].invoke
    Rake::Task['build:twitter_utils:ios'].invoke
    Rake::Task['build:facebook_utils:tvos'].invoke
    Rake::Task['build:parseui:framework'].invoke
    Rake::Task['build:parse_live_query:ios'].invoke
    Rake::Task['build:parse_live_query:macos'].invoke
    Rake::Task['build:parse_live_query:tvos'].invoke
    Rake::Task['build:parse_live_query:watchos'].invoke
  end
end

namespace :test do
  desc 'Run iOS Tests'
  task :ios do |_, args|
    task = XCTask::BuildTask.new do |t|
      t.directory = script_folder
      t.workspace = 'Parse.xcworkspace'

      t.scheme = 'Parse-iOS'
      t.sdk = 'iphonesimulator'
      t.destinations = [ios_simulator]
      t.configuration = 'Debug -enableCodeCoverage YES'

      t.actions = [XCTask::BuildAction::TEST]
      t.formatter = XCTask::BuildFormatter::XCODEBUILD
    end
    unless task.execute
      puts 'iOS Tests Failed!'
      exit(1)
    end
  end

  desc 'Run macOS Tests'
  task :macos do |_, args|
    task = XCTask::BuildTask.new do |t|
      t.directory = script_folder
      t.workspace = 'Parse.xcworkspace'

      t.scheme = 'Parse-macOS'
      t.sdk = 'macosx'
      t.configuration = 'Debug -enableCodeCoverage YES'

      t.actions = [XCTask::BuildAction::TEST]
      t.formatter = XCTask::BuildFormatter::XCODEBUILD
    end
    unless task.execute
      puts 'macOS Tests Failed!'
      exit(1)
    end
  end

  namespace :facebook_utils do
    desc 'Test iOS FacebookUtils framework.'
    task :ios do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseFacebookUtilsV4-iOS'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug -enableCodeCoverage YES'

        t.actions = [XCTask::BuildAction::TEST]
        t.formatter = XCTask::BuildFormatter::XCODEBUILD
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS FacebookUtils Framework.'
        exit(1)
      end
    end
  end

  namespace :twitter_utils do
    desc 'Test iOS TwitterUtils framework.'
    task :ios do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseTwitterUtils-iOS'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug -enableCodeCoverage YES'

        t.actions = [XCTask::BuildAction::TEST]
        t.formatter = XCTask::BuildFormatter::XCODEBUILD
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS TwitterUtils Framework.'
        exit(1)
      end
    end
  end

  namespace :parseui do
    task :all do
      Rake::Task['test:parseui:framework'].invoke
      Rake::Task['test:parseui:demo_objc'].invoke
    end

    task :framework do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseUI'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug -enableCodeCoverage YES'

        t.actions = [XCTask::BuildAction::TEST]
        t.formatter = XCTask::BuildFormatter::XCODEBUILD
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseUI'
        exit(1)
      end
    end

    task :demo_objc do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseUIDemo'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug'

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseUI Demo.'
        exit(1)
      end
    end

    task :demo_swift do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseUIDemo-Swift'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug'

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS ParseUI Swift Demo.'
        exit(1)
      end
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
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseLiveQuery-iOS'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]
        t.configuration = 'Debug'

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseLiveQuery'
        exit(1)
      end
    end

    task :tvos do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseLiveQuery-tvOS'
        t.destinations = [tvos_simulator]
        t.configuration = 'Debug'
        

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseLiveQuery-tvOS.'
        exit(1)
      end
    end

    task :watchos do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseLiveQuery-watchOS'
        t.destinations = [watchos_simulator]
        t.configuration = 'Debug'
        

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseLiveQuery-watchOS.'
        exit(1)
      end
    end
    
    task :osx do
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = 'ParseLiveQuery-OSX'
        t.configuration = 'Debug'
    

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseLiveQuery-OSX.'
        exit(1)
      end
    end
  end

  desc 'Build Starter Project'
  task :starters do |_|
    results = []
    ios_schemes = ['ParseStarterProject',
                   'ParseStarterProject-Swift']
    osx_schemes = ['ParseOSXStarterProject',
                   'ParseOSXStarterProject-Swift']
    tvos_schemes = ['ParseStarter-tvOS']
    watchos_schemes = ['ParseWatchStarter-watchOS']

    ios_schemes.each do |scheme|
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = scheme
        t.configuration = 'Debug'
        t.sdk = 'iphonesimulator'
        t.destinations = [ios_simulator]

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      results << task.execute
    end
    osx_schemes.each do |scheme|
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = scheme
        t.configuration = 'Debug'
        t.sdk = 'macosx'

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      results << task.execute
    end
    watchos_schemes.each do |scheme|
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = scheme
        t.configuration = 'Debug'
        t.destinations = [ios_simulator]

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      results << task.execute
    end
    tvos_schemes.each do |scheme|
      task = XCTask::BuildTask.new do |t|
        t.directory = script_folder
        t.workspace = 'Parse.xcworkspace'

        t.scheme = scheme
        t.configuration = 'Debug'
        t.destinations = [tvos_simulator]

        t.actions = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD]
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      results << task.execute
    end

    results.each do |result|
      unless result
        puts 'Starter Project Tests Failed!'
        exit(1)
      end
    end
  end
end
