# frozen_string_literal: true

require 'fileutils'
require 'open3'

# A simulator-only executable prepares the hinge without adding private APIs to the app.
module DuoScreenshotSimulator
  def self.open(udid, runtime:)
    binary = pose_binary(runtime)
    raise 'Unable to boot Duo' unless system('xcrun', 'simctl', 'bootstatus', udid, '-b')
    raise 'Unable to open Duo inner display' unless system('xcrun', 'simctl', 'spawn', udid, binary, udid, '180')
  end

  def self.pose_binary(runtime)
    directory = File.expand_path('../../.agent-artifacts/screenshot-simulator-tools', __dir__)
    FileUtils.mkdir_p(directory)
    architecture = `uname -m`.strip
    source = File.join(__dir__, 'duo_screenshot_pose.m')
    binary = File.join(directory, "duo-pose-#{architecture}-#{runtime}")
    compile_pose(binary, source, architecture, runtime) unless compiled?(binary, source)
    binary
  end

  def self.compiled?(binary, source)
    File.exist?(binary) && File.mtime(binary) >= File.mtime(source)
  end

  def self.compile_pose(binary, source, architecture, runtime)
    sdk, status = Open3.capture2e('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path')
    raise sdk unless status.success?

    output, status = Open3.capture2e('xcrun', 'clang', '-target', "#{architecture}-apple-ios#{runtime}-simulator",
                                     '-isysroot', sdk.strip, '-fobjc-arc', '-fblocks', '-framework', 'Foundation', source, '-o', binary)
    raise output unless status.success?
  end

  def self.install(runtime:)
    @runtime = runtime
    Snapshot::SimulatorLauncherBase.prepend(Preparation) unless Snapshot::SimulatorLauncherBase.ancestors.include?(Preparation)
  end

  def self.runtime
    @runtime
  end

  # Apply the hinge pose after Snapshot erases and localizes its selected devices.
  module Preparation
    def prepare_simulators_for_launch(device_types, **options)
      super
      device_types.select { |name| name == 'iPhone Duo' }.each do |name|
        udid = Snapshot::TestCommandGenerator.device_udid(name)
        DuoScreenshotSimulator.open(udid, runtime: DuoScreenshotSimulator.runtime)
      end
    end
  end
end
