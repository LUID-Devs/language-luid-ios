#!/usr/bin/env ruby
require 'securerandom'

# Read the project file
pbxproj_path = 'LanguageLuid.xcodeproj/project.pbxproj'
content = File.read(pbxproj_path)

# Generate UUIDs for new files
def generate_uuid
  SecureRandom.hex(12).upcase
end

# Files to add with their groups
files_to_add = [
  { filename: 'RevenueCatConfig.swift', group: 'Config', path: '../Source/Config/RevenueCatConfig.swift' },
  { filename: 'RevenueCatManager.swift', group: 'Services', path: '../Source/Services/RevenueCatManager.swift' },
  { filename: 'SubscriptionViewModel.swift', group: 'ViewModels', path: '../Source/ViewModels/SubscriptionViewModel.swift' },
  { filename: 'PaywallView.swift', group: 'Paywall', path: '../Source/Views/Paywall/PaywallView.swift' },
  { filename: 'SubscriptionPlanCard.swift', group: 'Paywall', path: '../Source/Views/Paywall/SubscriptionPlanCard.swift' }
]

files_to_add.each do |file_info|
  filename = file_info[:filename]
  group_name = file_info[:group]
  file_path = file_info[:path]

  # Skip if already exists
  if content.include?(filename)
    puts "Skipping #{filename} (already in project)"
    next
  end

  file_uuid = generate_uuid
  build_uuid = generate_uuid

  # Add to PBXFileReference section
  file_ref_section_end = content.index('/* End PBXFileReference section */')
  new_file_ref = "\t\t#{file_uuid} /* #{filename} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{filename}; sourceTree = \"<group>\"; };\n"
  content.insert(file_ref_section_end, new_file_ref)
  puts "Added file reference for #{filename}"

  # Add to PBXBuildFile section
  build_section_end = content.index('/* End PBXBuildFile section */')
  new_build_ref = "\t\t#{build_uuid} /* #{filename} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_uuid} /* #{filename} */; };\n"
  content.insert(build_section_end, new_build_ref)
  puts "Added build reference for #{filename}"

  # Add to PBXSourcesBuildPhase (Sources)
  if content =~ /(\/\* Sources \*\/ = \{[^}]+files = \([^)]+)/m
    sources_section = $1
    sources_end_pos = content.index(sources_section) + sources_section.length
    new_source_entry = "\t\t\t\t#{build_uuid} /* #{filename} in Sources */,\n"
    content.insert(sources_end_pos, new_source_entry)
    puts "Added to Sources build phase for #{filename}"
  end

  # Add to appropriate group
  group_pattern = /#{Regexp.escape(group_name)} \/\* #{Regexp.escape(group_name)} \*\/ = \{[^}]+children = \([^)]+\)/m
  if content =~ group_pattern
    group_section = $&
    group_end_pos = content.index(group_section) + group_section.length
    new_group_entry = "\t\t\t\t#{file_uuid} /* #{filename} */,\n"
    content.insert(group_end_pos, new_group_entry)
    puts "Added to #{group_name} group for #{filename}"
  else
    puts "WARNING: Could not find #{group_name} group for #{filename}"
  end

  puts "Successfully added #{filename}"
  puts "---"
end

# Write back
File.write(pbxproj_path, content)
puts "Project file updated successfully!"
