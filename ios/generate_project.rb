require 'xcodeproj'

root = File.expand_path(File.dirname(__FILE__))
app_dir = File.join(root, 'BlinkitSharedCart')
project_path = File.join(root, 'BlinkitSharedCart.xcodeproj')

project = Xcodeproj::Project.new(project_path)

target = project.new_target(:application, 'BlinkitSharedCart', :ios, '17.0')

main_group = project.main_group.new_group('BlinkitSharedCart', app_dir)

def add_dir(project, target, parent_group, dir)
  Dir.entries(dir).sort.each do |entry|
    next if entry.start_with?('.')
    full_path = File.join(dir, entry)
    if File.directory?(full_path)
      if entry.end_with?('.xcassets')
        ref = parent_group.new_reference(full_path)
        target.resources_build_phase.add_file_reference(ref)
      else
        sub_group = parent_group.new_group(entry, full_path)
        add_dir(project, target, sub_group, full_path)
      end
    elsif entry.end_with?('.swift')
      ref = parent_group.new_reference(full_path)
      target.source_build_phase.add_file_reference(ref)
    elsif entry == 'Info.plist'
      parent_group.new_reference(full_path)
    end
  end
end

add_dir(project, target, main_group, app_dir)

target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'BlinkitSharedCart/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.hackathon.blinkitsharedcart'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['ENABLE_PREVIEWS'] = 'YES'
end

project.save
puts "Wrote #{project_path}"
