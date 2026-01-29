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
  { name: 'ProfileView.swift', group: 'Profile', path: 'Profile' },
  { name: 'EditProfileView.swift', group: 'Profile', path: 'Profile' },
  { name: 'ChangePasswordView.swift', group: 'Profile', path: 'Profile' },
  { name: 'NotificationSettingsView.swift', group: 'Profile', path: 'Profile' }
]

# First, check if Profile group exists, if not create it
profile_group_uuid = nil
if content =~ /\/\* Profile \*\/ = \{/
  puts "Profile group already exists"
  # Extract UUID
  if content =~ /([A-F0-9]{24}) \/\* Profile \*\/ = \{/
    profile_group_uuid = $1
  end
else
  puts "Creating Profile group..."
  profile_group_uuid = generate_uuid

  # Find Views group
  if content =~ /(([A-F0-9]{24}) \/\* Views \*\/ = \{[^}]+children = \([^)]+)/m
    views_section = $1
    views_uuid = $2
    views_end_pos = content.index(views_section) + views_section.length

    # Add Profile group reference to Views children
    new_group_ref = "\t\t\t\t#{profile_group_uuid} /* Profile */,\n"
    content.insert(views_end_pos, new_group_ref)

    # Add Profile group definition in PBXGroup section
    group_section_end = content.index('/* End PBXGroup section */')
    new_group_def = <<~GROUP
    \t\t#{profile_group_uuid} /* Profile */ = {
    \t\t\tisa = PBXGroup;
    \t\t\tchildren = (
    \t\t\t);
    \t\t\tname = Profile;
    \t\t\tpath = ../Source/Views/Profile;
    \t\t\tsourceTree = "<group>";
    \t\t};
    GROUP
    content.insert(group_section_end, new_group_def)
    puts "Profile group created with UUID: #{profile_group_uuid}"
  end
end

files.each do |file|
  filename = file[:name]

  # Skip if already exists
  if content.include?(filename)
    puts "#{filename} already exists, skipping"
    next
  end

  file_uuid = generate_uuid
  build_uuid = generate_uuid

  # Add PBXFileReference
  file_ref_section_end = content.index('/* End PBXFileReference section */')
  new_file_ref = "\t\t#{file_uuid} /* #{filename} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = #{filename}; path = #{file[:path]}/#{filename}; sourceTree = \"<group>\"; };\n"
  content.insert(file_ref_section_end, new_file_ref)

  # Add PBXBuildFile
  build_section_end = content.index('/* End PBXBuildFile section */')
  new_build_ref = "\t\t#{build_uuid} /* #{filename} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_uuid} /* #{filename} */; };\n"
  content.insert(build_section_end, new_build_ref)

  # Add to PBXSourcesBuildPhase
  if content =~ /(\/* Sources \*\/ = \{[^}]+files = \([^)]+)/m
    sources_section = $1
    sources_end_pos = content.index(sources_section) + sources_section.length
    new_source_entry = "\t\t\t\t#{build_uuid} /* #{filename} in Sources */,\n"
    content.insert(sources_end_pos, new_source_entry)
  end

  # Add to Profile group
  if profile_group_uuid && content =~ /(#{profile_group_uuid} \/\* Profile \*\/ = \{[^}]+children = \([^)]+)/m
    group_section = $1
    group_end_pos = content.index(group_section) + group_section.length
    new_group_entry = "\t\t\t\t#{file_uuid} /* #{filename} */,\n"
    content.insert(group_end_pos, new_group_entry)
  end

  puts "Added #{filename} to project"
end

# Write back
File.write(pbxproj_path, content)
puts "Project file updated successfully!"
