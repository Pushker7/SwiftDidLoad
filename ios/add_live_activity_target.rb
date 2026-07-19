#!/usr/bin/env ruby
# Adds the Live Activity widget extension to the existing Xcode project.
# Idempotent: re-running it will not duplicate the target or file references.

require 'xcodeproj'

root         = File.expand_path(File.dirname(__FILE__))
project_path = File.join(root, 'BlinkitSharedCart.xcodeproj')
app_dir      = File.join(root, 'BlinkitSharedCart')
widget_dir   = File.join(root, 'BlinkitCartWidget')

APP_TARGET    = 'BlinkitSharedCart'
WIDGET_TARGET = 'BlinkitCartWidget'
APP_BUNDLE_ID = 'com.hackathon.blinkitsharedcart'

project    = Xcodeproj::Project.open(project_path)
app_target = project.targets.find { |t| t.name == APP_TARGET }
abort "Could not find app target #{APP_TARGET}" unless app_target

# --- helpers ---------------------------------------------------------------

def find_or_create_group(parent, name, path)
  parent[name] || parent.new_group(name, path)
end

# Returns the existing file reference for `path` anywhere in the project, or creates one.
def file_ref(project, group, path)
  existing = project.files.find { |f| f.real_path.to_s == path }
  existing || group.new_reference(path)
end

def add_to_target_once(target, ref)
  already = target.source_build_phase.files.any? { |bf| bf.file_ref == ref }
  target.source_build_phase.add_file_reference(ref) unless already
end

# --- 1. shared + app-only Live Activity sources ----------------------------

app_group  = project.main_group[APP_TARGET] || project.main_group
la_group   = find_or_create_group(app_group, 'LiveActivity', 'LiveActivity')

attributes_path = File.join(app_dir, 'LiveActivity', 'BlinkitCartAttributes.swift')
manager_path    = File.join(app_dir, 'LiveActivity', 'LiveActivityManager.swift')

attributes_ref = file_ref(project, la_group, attributes_path)
manager_ref    = file_ref(project, la_group, manager_path)

add_to_target_once(app_target, attributes_ref)
add_to_target_once(app_target, manager_ref)

# --- 2. widget extension target --------------------------------------------

widget_target = project.targets.find { |t| t.name == WIDGET_TARGET }

unless widget_target
  widget_target = project.new_target(
    :app_extension,
    WIDGET_TARGET,
    :ios,
    '17.0',
    nil,
    :swift
  )
end

widget_group = find_or_create_group(project.main_group, WIDGET_TARGET, widget_dir)
widget_src   = file_ref(project, widget_group, File.join(widget_dir, 'BlinkitCartWidget.swift'))
file_ref(project, widget_group, File.join(widget_dir, 'Info.plist'))

add_to_target_once(widget_target, widget_src)
# The attributes type is compiled into BOTH targets so the payload shape matches.
add_to_target_once(widget_target, attributes_ref)

%w[WidgetKit SwiftUI].each do |framework|
  unless widget_target.frameworks_build_phase.files.any? { |f| f.display_name == "#{framework}.framework" }
    widget_target.add_system_framework(framework)
  end
end

widget_target.build_configurations.each do |config|
  config.build_settings.merge!(
    'INFOPLIST_FILE'                => 'BlinkitCartWidget/Info.plist',
    'PRODUCT_BUNDLE_IDENTIFIER'     => "#{APP_BUNDLE_ID}.#{WIDGET_TARGET}",
    'PRODUCT_NAME'                  => '$(TARGET_NAME)',
    'GENERATE_INFOPLIST_FILE'       => 'NO',
    'SKIP_INSTALL'                  => 'YES',
    'SWIFT_VERSION'                 => '5.0',
    'TARGETED_DEVICE_FAMILY'        => '1',
    'IPHONEOS_DEPLOYMENT_TARGET'    => '17.0',
    'CODE_SIGN_STYLE'               => 'Automatic',
    'LD_RUNPATH_SEARCH_PATHS'       => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  )
end

# --- 3. embed the extension in the app -------------------------------------

embed_phase = app_target.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && phase.name == 'Embed App Extensions'
end

unless embed_phase
  embed_phase = app_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
end

unless embed_phase.files.any? { |f| f.file_ref == widget_target.product_reference }
  build_file = embed_phase.add_file_reference(widget_target.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

unless app_target.dependencies.any? { |d| d.target == widget_target }
  app_target.add_dependency(widget_target)
end

project.save
puts "Live Activity widget extension wired into #{project_path}"
