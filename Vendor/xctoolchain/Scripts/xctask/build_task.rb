#!/usr/bin/env ruby
#
# Copyright (c) 2015-present, Parse, LLC.
# Portions Copyright (c) 2017-present, Nikita Lutsenko
#
# All rights reserved.
#
# This source code is licensed under the BSD-style license found
# in the LICENSE file in the root directory of this source tree.
#

module XCTask
  # This class defines all possible build formatters for BuildTask.
  class BuildFormatter
    XCODEBUILD = 'xcodebuild'
    XCPRETTY = 'xcpretty'
    XCTOOL = 'xctool'

    def self.verify(formatter)
      if formatter &&
         formatter != XCPRETTY &&
         formatter != XCODEBUILD &&
         formatter != XCTOOL
        fail "Unknown formatter used. Available formatters: 'xcodebuild', 'xcpretty', 'xctool'."
      end
    end
  end

  # This class defines all possible build actions for BuildTask.
  class BuildAction
    BUILD = 'build'
    CLEAN = 'clean'
    TEST = 'test'
    ANALYZE = 'analyze'

    def self.verify(action)
      if action.nil? ||
         (action != BUILD &&
         action != CLEAN &&
         action != TEST &&
         action != ANALYZE)
        fail "Unknown build action used. Available actions: 'build', 'clean', 'test', 'analyze'."
      end
    end
  end

  # This class adds ability to easily configure a xcodebuild task and execute it.
  class BuildTask
    attr_accessor :directory
    attr_accessor :workspace
    attr_accessor :project

    attr_accessor :scheme
    attr_accessor :sdk
    attr_accessor :configuration
    attr_accessor :destinations

    attr_accessor :additional_options
    attr_accessor :actions
    attr_accessor :formatter

    attr_accessor :reports_enabled

    def initialize
      @directory = '.'
      @destinations = []
      @additional_options = {}

      yield self if block_given?
    end

    def execute
      verify
      prepare_build
      build
    end

    private

    def verify
      BuildFormatter.verify(@formatter)
      @actions.each do |action|
        BuildAction.verify(action)
      end
    end

    def prepare_build
      Dir.chdir(@directory) unless @directory.nil?
    end

    def build
      system(build_command_string(@formatter))
    end

    def build_command_string(formatter)
      command_string = nil

      case formatter
      when BuildFormatter::XCODEBUILD
        command_string = 'xcodebuild ' + build_options_string
      when BuildFormatter::XCPRETTY
        command_string = build_command_string('xcodebuild') + ' | xcpretty -c'
        if @actions.include? BuildAction::TEST
          command_string += " --report junit --output build/reports/#{@sdk}.xml"
        end
        command_string += ' ; exit ${PIPESTATUS[0]}'
      when BuildFormatter::XCTOOL
        command_string = 'xctool ' + build_options_string
      else
        command_string = build_command_string(BuildFormatter::XCODEBUILD)
      end

      command_string
    end

    def build_options_string
      opts = []
      opts << "-workspace #{@workspace}" if @workspace
      opts << "-project #{@project}" if @project
      opts << "-scheme #{@scheme}" if @scheme
      opts << "-sdk #{@sdk}" if @sdk
      opts << "-configuration #{@configuration}" if @configuration
      @destinations.each do |d|
        opts << "-destination #{d}"
      end
      opts << @actions.compact.join(' ') if @actions

      @additional_options.each do |key, value|
        opts << "#{key}=#{value}"
      end

      opts.compact.join(' ')
    end
  end
end
