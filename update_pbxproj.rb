require 'xcodeproj'
project_path = 'boringNotch.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('boringNotch/managers', false)

# Remove PostProcessingService.swift
ref = group.files.find { |f| f.path == 'PostProcessingService.swift' }
if ref
  target.source_build_phase.remove_file_reference(ref)
  ref.remove_from_project
end

project.save
