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
starters_folder = File.join(script_folder, 'ParseStarterProject')
release_folder = File.join(build_folder, 'release')
bolts_build_folder = File.join(script_folder, 'Carthage', 'Build')
bolts_folder = File.join(script_folder, 'Carthage', 'Checkouts', 'Bolts-ObjC')
ios_simulator = 'platform="iOS Simulator",name="iPhone 14"'
tvos_simulator = 'platform="tvOS Simulator",name="Apple TV"'
watchos_simulator = 'platform="watchOS Simulator",name="Apple Watch Series 8 (45mm)"'

build_action = [XCTask::BuildAction::CLEAN, XCTask::BuildAction::BUILD];

module Constants
  require 'plist'

  script_folder = File.expand_path(File.dirname(__FILE__))

  PARSE_CONSTANTS_HEADER = File.join(script_folder, 'Parse', 'Parse', 'Source/PFConstants.h')

  PLISTS = [
    File.join(script_folder, 'Parse', 'Parse', 'Resources', 'Parse-iOS.Info.plist'),
    File.join(script_folder, 'Parse', 'Parse', 'Resources', 'Parse-OSX.Info.plist'),
    File.join(script_folder, 'Parse', 'Parse', 'Resources', 'Parse-watchOS.Info.plist'),
    File.join(script_folder, 'Parse', 'Parse', 'Resources', 'Parse-tvOS.Info.plist'),
    File.join(script_folder, 'ParseFacebookUtils', 'ParseFacebookUtils', 'Resources', 'Info-iOS.plist'),
    File.join(script_folder, 'ParseFacebookUtils', 'ParseFacebookUtils', 'Resources', 'Info-tvOS.plist'),
    File.join(script_folder, 'ParseTwitterUtils', 'ParseTwitterUtils', 'Resources', 'Info-iOS.plist'),
    File.join(script_folder, 'ParseUI', 'ParseUI', 'Resources', 'Info-iOS.plist'),
    File.join(script_folder, 'ParseLiveQuery', 'ParseLiveQuery', 'Resources', 'Info.plist'),
    File.join(script_folder, 'ParseLiveQuery', 'ParseLiveQuery-tvOS', 'Info.plist'),
    File.join(script_folder, 'ParseLiveQuery', 'ParseLiveQuery-watchOS', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'iOS', 'ParseStarterProject', 'Resources', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'iOS', 'ParseStarterProject-Swift', 'Resources', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'OSX', 'ParseOSXStarterProject', 'Resources', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'OSX', 'ParseOSXStarterProject-Swift', 'Resources', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'tvOS', 'ParseStarterProject-Swift', 'ParseStarter', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'watchOS', 'ParseStarterProject-Swift', 'ParseStarter', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'watchOS', 'ParseStarterProject-Swift', 'ParseStarter Extension', 'Info.plist'),
    File.join(script_folder, 'ParseStarterProject', 'watchOS', 'ParseStarterProject-Swift', 'Resources', 'Info.plist'),
  ]

  def self.current_version
    constants_file = File.open(PARSE_CONSTANTS_HEADER, 'r').read
    matches = constants_file.match(/(.*PARSE_VERSION\s*@")(.*)(")/)
    matches[2] # Return the second match, which is the version itself
  end

  def self.update_version(version)
    constants_file = File.open(PARSE_CONSTANTS_HEADER, 'r+')
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

        t.actions = build_action
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

        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build iOS ParseUI Swift Demo.'
        exit(1)
      end
    end
  end

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
    Rake::Task['build:ios_starters:all'].invoke
    Rake::Task['build:macos_starters:all'].invoke
    Rake::Task['build:tvos_starters:all'].invoke
    Rake::Task['build:watchos_starters:all'].invoke
  end
end

namespace :package do
  package_ios_name = 'Parse-iOS.zip'
  package_macos_name = 'Parse-macOS.zip'
  package_tvos_name = 'Parse-tvOS.zip'
  package_watchos_name = 'Parse-watchOS.zip'
  package_starter_ios_name = 'ParseStarterProject-iOS.zip'
  package_starter_osx_name = 'ParseStarterProject-OSX.zip'
  package_starter_tvos_name = 'ParseStarterProject-tvOS.zip'
  package_starter_watchos_name = 'ParseStarterProject-watchOS.zip'
  package_parseui_name = 'ParseUI.zip'

  task :prepare do
    `rm -rf #{build_folder} && mkdir -p #{build_folder}`
    `#{bolts_folder}/scripts/build_framework.sh -n -c Release --with-watchos --with-tvos`
  end

  task :set_version, [:version] do |_, args|
    version = args[:version] || Constants.current_version
    Constants.update_version(version)
  end

  desc 'Build all frameworks and starters'
  task :release do |_|
    Rake::Task['package:frameworks'].invoke
  end

  desc 'Build and package all frameworks for the release'
  task :frameworks, [:version] => :prepare do |_, args|
    version = args[:version] || Constants.current_version
    Constants.update_version(version)

    ## Build macOS Framework
    Rake::Task['build:macos'].invoke
    bolts_path = File.join(bolts_build_folder, 'osx', 'Bolts.framework')
    osx_framework_path = File.join(build_folder, 'Parse.framework')
    make_package(release_folder,
                 [osx_framework_path, bolts_path],
                 package_macos_name)

    ## Build iOS Framework
    Rake::Task['build:ios'].invoke
    bolts_path = File.join(bolts_build_folder, 'ios', 'Bolts.framework')
    ios_framework_path = File.join(build_folder, 'Parse.framework')
    make_package(release_folder,
                 [ios_framework_path, bolts_path],
                 package_ios_name)

    ## Build tvOS Framework
    Rake::Task['build:tvos'].invoke
    bolts_path = File.join(bolts_build_folder, 'tvOS', 'Bolts.framework')
    tvos_framework_path = File.join(build_folder, 'Parse.framework')
    make_package(release_folder,
                  [tvos_framework_path, bolts_path],
                  package_tvos_name)

    ## Build watchOS Framework
    Rake::Task['build:watchos'].invoke
    bolts_path = File.join(bolts_build_folder, 'watchOS', 'Bolts.framework')
    watchos_framework_path = File.join(build_folder, 'Parse.framework')
    make_package(release_folder,
                 [watchos_framework_path, bolts_path],
                 package_watchos_name)

    Rake::Task['build:facebook_utils:ios'].invoke
    ios_fb_utils_framework_path = File.join(build_folder, 'iOS', 'ParseFacebookUtilsV4.framework')
    make_package(release_folder, [ios_fb_utils_framework_path], 'ParseFacebookUtils-iOS.zip')

    Rake::Task['build:twitter_utils:ios'].invoke
    ios_tw_utils_framework_path = File.join(build_folder, 'iOS', 'ParseTwitterUtils.framework')
    make_package(release_folder, [ios_tw_utils_framework_path], 'ParseTwitterUtils-iOS.zip')

    Rake::Task['build:facebook_utils:tvos'].invoke
    tvos_fb_utils_framework_path = File.join(build_folder, 'tvOS', 'ParseFacebookUtilsV4.framework')
    make_package(release_folder, [tvos_fb_utils_framework_path], 'ParseFacebookUtils-tvOS.zip')

    Rake::Task['build:parseui:framework'].invoke
    parseui_framework_path = File.join(build_folder, 'iOS', 'ParseUI.framework')
    make_package(release_folder,
                [parseui_framework_path],
                package_parseui_name)
    
    Rake::Task['build:parse_live_query:ios'].invoke
    ios_lq_framework_path = File.join(build_folder, 'iOS', 'ParseLiveQuery.framework')
    make_package(release_folder, [ios_lq_framework_path], 'ParseLiveQuery-iOS.zip')

    Rake::Task['build:parse_live_query:watchos'].invoke
    watchos_lq_fb_utils_framework_path = File.join(build_folder, 'watchOS', 'ParseLiveQuery_watchOS.framework')
    make_package(release_folder, [watchos_lq_fb_utils_framework_path], 'ParseLiveQuery-watchOS.zip')

    Rake::Task['build:parse_live_query:tvos'].invoke
    tvos_lq_framework_path = File.join(build_folder, 'tvOS', 'ParseLiveQuery_tvOS.framework')
    make_package(release_folder, [tvos_lq_framework_path], 'ParseLiveQuery-tvOS.zip')

    Rake::Task['build:parse_live_query:macos'].invoke
    macos_lq_utils_framework_path = File.join(build_folder, 'macOS', 'ParseLiveQuery.framework')
    make_package(release_folder, [macos_lq_utils_framework_path], 'ParseLiveQuery-OSX.zip')
  end

  def make_package(target_path, items, archive_name)
    temp_folder = File.join(target_path, 'tmp')
    `mkdir -p #{temp_folder}`

    item_list = ''
    items.each do |item|
      `cp -R #{item} #{temp_folder}`

      file_name = File.basename(item)
      item_list << " #{file_name}"
    end

    archive_path = File.join(target_path, archive_name)
    `cd #{temp_folder}; zip -r --symlinks #{archive_path} #{item_list}`
    `rm -rf #{temp_folder}`
    puts "Release archive created: #{File.join(target_path, archive_name)}"
  end

  def make_starter_package(target_path, starter_projects, framework_archive, archive_name)
    starter_projects.each do |project_path|
      `git clean -xfd #{project_path}`
      `cd #{project_path} && unzip -o #{framework_archive}`

      xcodeproj_path = Dir.glob(File.join(project_path, '*.xcodeproj'))[0]
      prepare_xcodeproj(xcodeproj_path)
    end
    make_package(target_path, starter_projects, archive_name)

    starter_projects.each do |project_path|
      `git clean -xfd #{project_path}`
      `git checkout #{project_path}`
    end
  end

  def prepare_xcodeproj(path)
    project = Xcodeproj::Project.open(path)
    project.targets.each do |target|
      if target.name == 'Bootstrap'
        target.remove_from_project
      else
        target.dependencies.each do |dependency|
          dependency.remove_from_project if dependency.display_name == 'Bootstrap'
        end
      end
    end
    project.save

    `rm -rf #{File.join(path, 'xcshareddata', 'xcschemes', '*')}`
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

        t.actions = build_action
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

        t.actions = build_action
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

        t.actions = build_action
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
        

        t.actions = build_action
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
        

        t.actions = build_action
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
    

        t.actions = build_action
        t.formatter = XCTask::BuildFormatter::XCPRETTY
      end

      result = task.execute
      unless result
        puts 'Failed to build ParseLiveQuery-OSX.'
        exit(1)
      end
    end
  end
end
