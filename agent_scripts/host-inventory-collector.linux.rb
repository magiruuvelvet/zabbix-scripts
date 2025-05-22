#!/usr/bin/env ruby
# Linux system information collector.
# Works with Ruby 2.5+ and 3.x - some enterprise LTS distributions are stuck on Ruby 2.5 with security patches.

require "json"
require "ostruct"
require "socket"

# ensure portable CLI output
ENV["LC_ALL"] = "C"
ENV["LANGUAGE"] = ""

# constants
OS_RELEASE_FILE_PATH = "/etc/os-release".freeze
PROC_MEMINFO_PATH = "/proc/meminfo".freeze
SYS_CHASSIS_VENDOR_PATH = "/sys/class/dmi/id/chassis_vendor".freeze

CUSTOM_USER_DATA_PATH = "/etc/zabbix/host-inventory.user.json".freeze

# Returns custom user-provided data that will be mixed into the final JSON.
#
# @return [Hash<String, Object>]
def get_custom_user_data
  return {} unless File.exist?(CUSTOM_USER_DATA_PATH)
  return JSON.parse(File.read(CUSTOM_USER_DATA_PATH, mode: "r"))
end

# Get OS release information from `/etc/os-release`.
#
# @param [Array<String>] keys
# @return [Hash<String, String>]
def get_values_from_os_release(keys)
  return {} unless File.exist?(OS_RELEASE_FILE_PATH)

  result = OpenStruct.new
  keys.each do |key|
    result[:"#{key.downcase}"] = ""
  end

  File.readlines(OS_RELEASE_FILE_PATH).each do |line|
    keys.each do |key|
      if line.start_with?("#{key}=")
        result[:"#{key.downcase}"] = line.split('=', 2)[1].strip.gsub('"', '')
      end
    end
  end

  return result
end

# Returns the total system memory in bytes.
#
# @return [Integer]
def get_total_system_memory
  File.readlines(PROC_MEMINFO_PATH).each do |t|
    return t.split(/ +/)[1].to_i * 1024 if t.start_with?("MemTotal:")
  end

  return 0
end

# Returns the virtualization status.
#
# @return [Hash]
def get_virtualization_status
  virt_status = `systemd-detect-virt --vm`.strip

  return {
    is_virtualized: virt_status != "none",
    environment: virt_status,
  }
end

# Returns the chassis vendor if available.
#
# @return [String]
def get_chassis_vendor
  return "" unless File.exist?(SYS_CHASSIS_VENDOR_PATH)
  return File.read(SYS_CHASSIS_VENDOR_PATH, mode: "r").strip
end

# Obtain the short operating system name.
#
# @return [String]
def get_os_name_short
  `uname`.strip
end

class CpuInfo
  # @return [String]
  attr_accessor :vendor

  # @return [String]
  attr_accessor :model_name

  # @return [String]
  attr_accessor :architecture

  # @return [Integer]
  attr_accessor :cores

  # @return [Integer]
  attr_accessor :threads_per_core

  # @return [Integer]
  attr_accessor :freq_min

  # @return [Integer]
  attr_accessor :freq_max

  def initialize
    self.vendor = ""
    self.model_name = ""
    self.architecture = ""
    self.cores = 0
    self.threads_per_core = 0
    self.freq_min = 0
    self.freq_max = 0
  end

  def self.get_cpu_info
    cpu_info = CpuInfo.new
    cpu_info_raw = JSON.parse(`lscpu --json`, symbolize_names: true)

    cpu_info_raw[:lscpu].each do |field|
      case field[:field]
        when "Architecture:"
          cpu_info.architecture = field[:data]
        when "Model name:"
          cpu_info.model_name = field[:data]
        when "Vendor ID:"
          cpu_info.vendor = field[:data]
        when "Core(s) per socket:"
          cpu_info.cores = field[:data].to_i
        when "Thread(s) per core:"
          cpu_info.threads_per_core = field[:data].to_i
        when "CPU min MHz:"
          cpu_info.freq_min = field[:data].to_i
        when "CPU max MHz:"
          cpu_info.freq_max = field[:data].to_i
      end
    end

    return cpu_info
  end
end

os_release = get_values_from_os_release(["ID", "VERSION_ID", "NAME", "PRETTY_NAME"])
cpu_info = CpuInfo.get_cpu_info
virt_status = get_virtualization_status

# build system information hash
system_info = {
  hostname: Socket.gethostname,
  os: {
    name: get_os_name_short,
    release_id: os_release.id,
    release_version_id: os_release.version_id,
    release_name: os_release.name,
    release_pretty_name: os_release.pretty_name,
  },
  cpu: {
    vendor: cpu_info.vendor,
    model: cpu_info.model_name,
    architecture: cpu_info.architecture,
    cores: cpu_info.cores,
    threads: cpu_info.cores * cpu_info.threads_per_core,
    freq_min: cpu_info.freq_min,
    freq_max: cpu_info.freq_max,
  },
  mem: {
    total: get_total_system_memory,
  },
  virt: {
    is_virtualized: virt_status[:is_virtualized],
    environment: virt_status[:environment],
  },
  chassis: {
    vendor: get_chassis_vendor,
  },
  custom_user_data: get_custom_user_data,
}

puts JSON.pretty_generate(system_info)
