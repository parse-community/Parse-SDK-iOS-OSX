#!/usr/bin/env ruby
#
# Copyright (c) 2015-present, Parse, LLC.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.
#

framework_path = ARGV[0]
build_script = ARGV[1]

if framework_path.nil? || build_script.nil?
  puts "Use this script to build a third party framework for iOS/OSX."
  puts "It is intended to support building Bolts.framework and FacebookSDK.framework"
  puts "Usage: 'build_third_party.sh <framework_path> <build_script_path>"
  exit(1)
end

# Don't use rubygems git to make it run in any environment
last_revision = `git log -n 1 --format=%h #{framework_path}`

build_revision_path = File.join(framework_path, 'build', 'build_revision')
build_revision = File.exist?(build_revision_path) ? File.open(build_revision_path, 'rb').read : nil

if last_revision == build_revision
  puts "No changes in #{framework_path}. Skipping build."
else
  puts "Found local changes in #{framework_path}. Building third party."

  result = system("XCTOOL=xcodebuild ./#{build_script}")
  if result
    File.open(build_revision_path, 'w') { |f| f.write(last_revision) }
    exit(0)
  else
    exit(1)
  end
end
