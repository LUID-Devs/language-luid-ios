#!/usr/bin/env ruby
require 'securerandom'

# Read the project file
pbxproj_path = 'LanguageLuid.xcodeproj/project.pbxproj'
content = File.read(pbxproj_path)

# Generate UUIDs for new files (using simpler format)
def generate_uuid
  SecureRandom.hex(12).upcase
end

files = [
  'CreditsDetailView.swift',
  'SubscriptionManagementView.swift',
  'TransactionHistoryView.swift'
]

files.each do |filename|
  # Skip if already exists
  next if content.include?(filename)
  
  file_uuid = generate_uuid
  build_uuid = generate_uuid
  
  # Find the InfoScreens reference to understand the structure
  if content =~ /([A-F0-9]+) \/\* InfoScreens\.swift \*\//
    reference_pattern = $1
    
    # Find where InfoScreens is in PBXFileReference
    file_ref_section = content[/\/\* Begin PBXFileReference section \*\/.*?\/\* End PBXFileReference section \*\//m]
    
    if file_ref_section =~ /(.*InfoScreens\.swift.*)/
      reference_line = $1
      # Add new file reference after InfoScreens
      new_file_ref = reference_line.gsub(/[A-F0-9]+/, file_uuid).gsub('InfoScreens.swift', filename)
      
      insert_pos = content.index('/* End PBXFileReference section */')
      content.insert(insert_pos, "\t\t#{new_file_ref}\n")
    end
    
    # Find PBXBuildFile section and add build reference
    build_section_end = content.index('/* End PBXBuildFile section */')
    new_build_ref = "\t\t#{build_uuid} /* #{filename} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_uuid} /* #{filename} */; };\n"
    content.insert(build_section_end, new_build_ref)
    
    # Find PBXSourcesBuildPhase and add to files array
    if content =~ /(\/\* Sources \*\/ = \{[^}]+files = \([^)]+)/m
      sources_section = $1
      sources_end_pos = content.index(sources_section) + sources_section.length
      new_source_entry = "\t\t\t\t#{build_uuid} /* #{filename} in Sources */,\n"
      content.insert(sources_end_pos, new_source_entry)
    end
    
    # Find More group and add file
    if content =~ /(More \/\* More \*\/ = \{[^}]+children = \([^)]+)/m
      more_group = $1
      more_end_pos = content.index(more_group) + more_group.length
      new_group_entry = "\t\t\t\t#{file_uuid} /* #{filename} */,\n"
      content.insert(more_end_pos, new_group_entry)
    end
  end
  
  puts "Added #{filename} to project"
end

# Write back
File.write(pbxproj_path, content)
puts "Project file updated successfully!"
