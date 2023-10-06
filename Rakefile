#
# Copyright (c) 2015-present, Parse, LLC.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

require_relative 'Vendor/xctoolchain/Scripts/xctask/build_task'

script_folder = File.expand_path(File.dirname(__FILE__))
build_folder = File.join(script_folder, 'build')
starters_folder = File.join(script_folder, 'ParseStarterProject')

ios_simulator = 'platform="iOS Simulator",name="iPhone 14"'
tvos_simulator = 'platform="tvOS Simulator",name="Apple TV"'
watchos_simulator = 'platform="watchOS Simulator",name="Apple Watch Series 8 (45mm)"'

build_action = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD];

namespace :build do
  namespace :ios_starters do
    task :all do
      Rake::Task['build:ios_starters:objc'].invoke
      Rake::Task['build:ios_starters:swift'].invoke
    end

    task :objc do
      project = 'ParseStarterProject'
      ios_starters_folder = File.join(starters_folder, 'iOS', project)
      task = XCTask::BuildTask.new do |t|
        t.directory = ios_starters_folder
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
      project = 'ParseStarterProject-Swift'
      ios_starters_folder = File.join(starters_folder, 'iOS', project)
      task = XCTask::BuildTask.new do |t|
        t.directory = ios_starters_folder
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
      macos_starter_folder = File.join(starters_folder, 'OSX', 'ParseOSXStarterProject')
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
      macos_starter_folder = File.join(starters_folder, 'OSX', 'ParseOSXStarterProject-Swift')
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
      tvos_starter_folder = File.join(starters_folder, 'tvOS', 'ParseStarterProject-Swift')
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
      watchos_starter_folder = File.join(starters_folder, 'watchOS', 'ParseStarterProject-Swift')
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

  desc 'Build all starters'
  task :starters do
    Rake::Task['build:tvos_starters:all'].invoke
    Rake::Task['build:watchos_starters:all'].invoke
    Rake::Task['build:ios_starters:all'].invoke
    Rake::Task['build:macos_starters:all'].invoke
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
      t.formatter = XCTask::BuildFormatter::XCPRETTY
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
      t.formatter = XCTask::BuildFormatter::XCPRETTY
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
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end
      unless task.execute
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
