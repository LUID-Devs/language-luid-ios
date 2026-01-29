#!/usr/bin/env ruby
require 'securerandom'

# Read the project file
pbxproj_path = 'LanguageLuid.xcodeproj/project.pbxproj'
content = File.read(pbxproj_path)

# Generate UUIDs
def generate_uuid
  SecureRandom.hex(12).upcase
end

# Lessons group UUID
lessons_group_uuid = '4D8B683E2F1E801D00E005B2'

filename = 'ContinueLearningView.swift'

# Skip if already exists
if content.include?(filename)
  puts "#{filename} already exists, skipping"
  exit 0
end

file_uuid = generate_uuid
build_uuid = generate_uuid

puts "Adding #{filename}..."
puts "  File UUID: #{file_uuid}"
puts "  Build UUID: #{build_uuid}"

# Add PBXFileReference
file_ref_section_end = content.index('/* End PBXFileReference section */')
new_file_ref = "\t\t#{file_uuid} /* #{filename} */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = #{filename}; sourceTree = \"<group>\"; };\n"
content.insert(file_ref_section_end, new_file_ref)

# Add PBXBuildFile
build_section_end = content.index('/* End PBXBuildFile section */')
new_build_ref = "\t\t#{build_uuid} /* #{filename} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_uuid} /* #{filename} */; };\n"
content.insert(build_section_end, new_build_ref)

# Add to PBXSourcesBuildPhase
if content =~ /(\/\* Sources \*\/ = \{[^}]+files = \([^)]+)/m
  sources_section = $1
  sources_end_pos = content.index(sources_section) + sources_section.length
  new_source_entry = "\t\t\t\t#{build_uuid} /* #{filename} in Sources */,\n"
  content.insert(sources_end_pos, new_source_entry)
  puts "  ✓ Added to Sources build phase"
end

# Add to Lessons group
if content =~ /(#{lessons_group_uuid} \/\* Lessons \*\/ = \{[^}]+children = \([^)]+)/m
  group_section = $1
  group_end_pos = content.index(group_section) + group_section.length
  new_group_entry = "\t\t\t\t#{file_uuid} /* #{filename} */,\n"
  content.insert(group_end_pos, new_group_entry)
  puts "  ✓ Added to Lessons group"
end

# Write back
File.write(pbxproj_path, content)
puts "\n✓ #{filename} added successfully!"
