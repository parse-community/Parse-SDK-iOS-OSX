#!/usr/bin/env ruby
#
# Copyright (c) 2014, Parse, LLC. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Parse.
#
# As with any software that integrates with the Parse platform, your use of
# this software is subject to the Parse Terms of Service
# [https://www.parse.com/about/terms]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# This script generates Objective-C byte arrays from the png images.

require 'time'
require 'fileutils'

PATH_PREFIX = ARGV[0]
SEARCH_PATH = "#{PATH_PREFIX}**/*.{png,jpg,jpeg,gif}"

def make_varname(filename)
  varname = filename[PATH_PREFIX.length...filename.length]
  varname.gsub!("@", "")
  varname.gsub!(/[.\/\-]/, "_")
  varname
end

def get_modified_time_from_header(header_filename_with_path, source_filename_with_path)
  resource_modified_time = {} # maps resource filename to the file's modified time
  if File.exist?(header_filename_with_path) && File.exist?(source_filename_with_path)
    File.open(header_filename_with_path, "r") do |header_file|
      puts "Collect timestamps of previously generated resource files"
      header_file.each_line do |line|
        # puts line
        match = %r{NSData\s\*\)(.*);//modified:(.*)$}.match(line)
        next unless match

        resource_filename = Regexp.last_match[1]
        mtime = Regexp.last_match[2]
        puts "resource_filename #{resource_filename}"
        puts "time #{mtime}"
        resource_modified_time[resource_filename] = Time.parse mtime
      end
    end
  end
  resource_modified_time
end

def files_differ(resource_modified_time)
  Dir.glob(SEARCH_PATH) do |filename|
    filename_varname = make_varname(filename)
    if resource_modified_time[filename_varname].nil?
      puts "New file #{filename_varname} is added to resources"
      return true
    end

    if resource_modified_time[filename_varname] != File.mtime(filename)
      puts "A resource file #{filename_varname} had been modified since the header was created"
      return true
    end
    resource_modified_time.delete filename_varname
  end

  if resource_modified_time.keys.count != 0
    puts "Some files are present in the header but are not present in resources."
    puts "This indicates some resource files have been removed since last time PFResource.h was generated."
    return true
  end

  puts "The set of files in resources and the set of files in header are identical matches"
  puts "Not generating resource files"
  false
end

output_path = File.dirname(ARGV[1])
output_classname = File.basename(ARGV[1])

# We write to temp files and copy over temp files to the final files in the end.
# This way, Xcode does not pick up the intermediate result files and flag them as build errors.
# If developers see these temporary build errors, they will inevitably think the script is broken.
FileUtils.mkdir_p(output_path)

output_header_filename = output_classname + "Temp.h"
output_source_filename = output_classname + "Temp.m"
final_output_header_filename = output_classname + ".h"
final_output_source_filename = output_classname + ".m"
header_filename_with_path = File.join(output_path, output_header_filename)
source_filename_with_path = File.join(output_path, output_source_filename)
final_output_header_filename_with_path = File.join(output_path, final_output_header_filename)
final_output_source_filename_with_path = File.join(output_path, final_output_source_filename)

if ARGV.nil? || !(ARGV.include?("-f") || ARGV.include?("-forced"))
  resource_modified_time = get_modified_time_from_header(final_output_header_filename_with_path,
                                                         final_output_source_filename_with_path)
  exit if !files_differ(resource_modified_time)
end

puts "Regenerating resource byte array files"
# generate header and source files
output_header_file = File.open(header_filename_with_path, "w")
output_source_file = File.open(source_filename_with_path, "w")

output_header_file.write <<HEREDOC
// This is an auto-generated file.
#import <Foundation/Foundation.h>
@interface #{output_classname} : NSObject
HEREDOC

output_source_file.write <<HEREDOC
// This is an auto-generated file.
#import "#{final_output_header_filename}"
@implementation #{output_classname}
HEREDOC

Dir.glob(SEARCH_PATH) do |filename|
  filename_varname = make_varname(filename)
  puts "Creating #{filename_varname}"
  result = "static const unsigned char #{filename_varname}[] = { "
  count = 0
  resource_file = File.open(filename, "r")
  resource_file.each_byte do |byte|
    if count > 0
      result << ", "
    end
    result << "0x#{byte.to_s(16)}"
    count += 1
  end
  result << " };\n\n"

  output_header_file.write <<HEREDOC
+ (NSData *)#{filename_varname};//modified:#{File.mtime(resource_file)}
HEREDOC

  output_source_file.write <<HEREDOC
  #{result}

  + (NSData *)#{filename_varname} {
    return [NSData dataWithBytes:#{filename_varname} length:sizeof(#{filename_varname})];
  }

HEREDOC
end

output_header_file.write("@end\n")
output_source_file.write("@end\n")
output_header_file.close
output_source_file.close

puts "Copying from temp to final files"
FileUtils.cp(header_filename_with_path, final_output_header_filename_with_path)
FileUtils.cp(source_filename_with_path, final_output_source_filename_with_path)
FileUtils.rm(header_filename_with_path, :force => true)
FileUtils.rm(source_filename_with_path, :force => true)

puts "Done regenerating resource byte array files"
