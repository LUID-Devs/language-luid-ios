#!/usr/bin/env ruby
require 'securerandom'

# Read the project file
pbxproj_path = 'LanguageLuid.xcodeproj/project.pbxproj'
content = File.read(pbxproj_path)

# Generate UUIDs for new files
def generate_uuid
  SecureRandom.hex(12).upcase
end

# Files to add
files = [
  { name: 'ContinueLearningViewModel.swift', group: 'ViewModels', path: '../Source/ViewModels' },
  { name: 'ContinueLearningView.swift', group: 'Lessons', path: '../Source/Views/Lessons' },
  { name: 'LessonProgressCard.swift', group: 'Components', path: '../Source/Views/Components' },
  { name: 'ActivityTimelineItem.swift', group: 'Components', path: '../Source/Views/Components' }
]

files.each do |file|
  filename = file[:name]
  group_name = file[:group]
  file_path = file[:path]

  # Skip if already exists
  next if content.include?(filename)

  file_uuid = generate_uuid
  build_uuid = generate_uuid

  # Add PBXFileReference
  file_ref_section_end = content.index('/* End PBXFileReference section */')
  new_file_ref = "\t\t#{file_uuid} /* #{filename} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = #{filename}; path = #{file_path}/#{filename}; sourceTree = \"<group>\"; };\n"
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
  end

  # Add to appropriate group
  group_pattern = /#{group_name} \/\* #{group_name} \*\/ = \{[^}]+children = \([^)]+/m
  if content =~ group_pattern
    group_section = $&
    group_end_pos = content.index(group_section) + group_section.length
    new_group_entry = "\t\t\t\t#{file_uuid} /* #{filename} */,\n"
    content.insert(group_end_pos, new_group_entry)
  else
    puts "Warning: Could not find #{group_name} group for #{filename}"
  end

  puts "Added #{filename} to project in #{group_name} group"
end

# Write back
File.write(pbxproj_path, content)
puts "Project file updated successfully!"
