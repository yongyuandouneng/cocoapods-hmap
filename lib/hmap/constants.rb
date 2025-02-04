module HMap
  # This modules groups all the constants known to HMap.
  #
  class Constants
    BUILD_DIR = 'BUILD_DIR'
    BUILD_DIR_KEY = '${BUILD_DIR}'
    OBJROOT = 'OBJROOT'
    SRCROOT = '${SRCROOT}'
    HMAP_DIR = 'HMap'
    HMAP_GEN_DIR = 'HMAP_GEN_DIR'
    HMAP_GEN_DIR_VALUE = '${HMAP_GEN_DIR}'
    XCBuildData = 'XCBuildData'
    PROJECT_TEMP_DIR = '${PROJECT}.build'
    TARGET_TEMP_DIR = '${TARGET_NAME}.build'
    TARGET_NAME = '${TARGET_NAME}'
    PRODUCT_NAME = 'PRODUCT_NAME'
    PRODUCT_NAME_VALUE = '${PRODUCT_NAME}'
    CONFIGURATION_EFFECTIVE_PLATFORM = '$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)'
    USE_HEADERMAP = 'USE_HEADERMAP'
    USER_HEADER_SEARCH_PATHS = 'USER_HEADER_SEARCH_PATHS'
    HEADER_SEARCH_PATHS = 'HEADER_SEARCH_PATHS'
    HMAP_HEADER_SETTING = 'HMAP_HEADER_SETTING'
    HMAP_HEADER_SETTING_KEY = '${HMAP_HEADER_SETTING}'

    OTHER_CFLAGS = 'OTHER_CFLAGS'
    OTHER_CPLUSPLUSFLAGS = 'OTHER_CPLUSPLUSFLAGS'
    CONFIGURATION_BUILD_DIR = 'CONFIGURATION_BUILD_DIR'

    XCBuildConfiguration = Xcodeproj::Project::Object::XCBuildConfiguration
    PBXSourcesBuildPhase = Xcodeproj::Project::Object::PBXSourcesBuildPhase
    PBXHeadersBuildPhase = Xcodeproj::Project::Object::PBXHeadersBuildPhase
    PBXGroup = Xcodeproj::Project::Object::PBXGroup
    PBXFileReference = Xcodeproj::Project::Object::PBXFileReference
    PBXBuildFile = Xcodeproj::Project::Object::PBXBuildFile
    PBXAggregateTarget = Xcodeproj::Project::Object::PBXAggregateTarget

    HMAP_TARGET_ROOT = [BUILD_DIR_KEY, '..', '..', HMAP_DIR,
                        PROJECT_TEMP_DIR, CONFIGURATION_EFFECTIVE_PLATFORM,
                        TARGET_TEMP_DIR].join('/')

    HMAP_GEN_DIR_ATTRIBUTE = { HMAP_GEN_DIR => HMAP_TARGET_ROOT }

    HMAP_FILE_TYPE = %i[own_target_headers all_non_framework_target_headers all_target_headers all_product_headers
                        project_headers workspace_headers]

    def self.instance
      @instance ||= new
    end

    # Sets the current config instance. If set to nil the config will be
    # recreated when needed.
    #
    # @param  [Config, Nil] the instance.
    #
    # @return [void]
    #
    class << self
      attr_writer :instance
    end

    # def full_product_name(name, type)
    #   name.join('.', FILE_TYPES_BY_EXTENSION[type])
    # end

    def hmap_filename(type)
      filenames[type]
    end

    def full_hmap_filename(type, product_name = nil)
      name = hmap_filename(type)
      name = "#{product_name}-#{name}" if type != :all_product_headers && !product_name.nil?
      name
    end

    def full_hmap_filepath(type, path, dir = nil, product_name = nil)
      name = full_hmap_filename(type, product_name) unless path.end_with?(hmap_filename(type))
      path = Pathname.new(path)
      path = path.join(dir) unless dir.nil?
      path = path.join(name) unless name.nil?
      path
    end

    def hmap_build_setting_key(type)
      build_setting_keys(type)
    end

    def hmap_build_setting_values
      ss = build_setting_values.values.join(' ')
      ['$(inherited)', ss].join(' ')
    end

    def hmap_build_setting_value(type)
      build_setting_values[type]
    end

    def hmap_xc_filename(type)
      xc_filenames[type]
    end

    def hmap_build_settings
      build_settings
    end

    private

    def build_settings
      return @build_settings if defined? @build_settings

      attributes = HMAP_GEN_DIR_ATTRIBUTE
      settings = hmap_build_setting_values
      #   attributes[HMAP_HEADER_SETTING] = settings
      attributes[HEADER_SEARCH_PATHS] = build_setting_values_i
      attributes[OTHER_CFLAGS] = build_setting_values_c
      attributes[OTHER_CPLUSPLUSFLAGS] = build_setting_values_c
      attributes[USER_HEADER_SEARCH_PATHS] = build_setting_values_iquote
      #   attributes[OTHER_CFLAGS] = HMAP_HEADER_SETTING_KEY
      #   attributes[OTHER_CPLUSPLUSFLAGS] = HMAP_HEADER_SETTING_KEY
      attributes[USE_HEADERMAP] = 'NO'
      @build_settings = attributes
    end

    def filenames
      return @filenames if defined? @filenames

      @filenames = Hash[HMAP_FILE_TYPE.map do |type|
        t_type = type
        t_type = :all_target_headers if type == :workspace_headers
        name = t_type.to_s.gsub(/_/, '-')
        extname = '.hmap'
        extname = '.yaml' if type == :all_product_headers
        [type, name + extname]
      end]
    end

    def build_setting_values_i
      %i[own_target_headers all_non_framework_target_headers].map do |type|
        value = xc_filenames[type]
        "\"#{HMAP_GEN_DIR_VALUE}/#{value}\""
      end.join(' ')
    end

    def build_setting_values_iquote
      %i[project_headers all_target_headers].map do |type|
        value = xc_filenames[type]
        "\"#{HMAP_GEN_DIR_VALUE}/#{value}\""
      end.join(' ')
    end

    def build_setting_values_c
      %i[all_target_headers all_product_headers].map do |type|
        key = build_setting_keys[type]
        value = xc_filenames[type]
        blank = ' ' unless key == :I
        ["-#{key}", "\"#{HMAP_GEN_DIR_VALUE}/#{value}\""].join(blank || '')
      end.join(' ')
    end

    def build_setting_keys
      return @build_setting_keys if defined? @build_setting_keys

      @build_setting_keys =
        Hash[HMAP_FILE_TYPE.map do |type|
               [type, case type
                      when :workspace_headers, :project_headers then :iquote
                      when :all_product_headers then :ivfsoverlay
                      else
                        :I
                      end]
             end]
    end

    def build_setting_values
      return @build_setting_values if defined? @build_setting_values

      @build_setting_values =
        Hash[HMAP_FILE_TYPE.map do |type|
               key = build_setting_keys[type]
               value = xc_filenames[type]
               blank = ' ' unless key == :I
               [type, ["-#{key}", "\"#{HMAP_GEN_DIR_VALUE}/#{value}\""].join(blank || '')]
             end]
    end

    def xc_filenames
      return @xc_filenames if defined? @xc_filenames

      @xc_filenames =
        Hash[HMAP_FILE_TYPE.map do |type|
               file_name = filenames[type]
               [type, case type
                      when :all_product_headers then file_name
                      else
                        "#{Constants::PRODUCT_NAME_VALUE}-#{file_name}"
                      end]
             end]
    end
  end
end
