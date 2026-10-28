#!/usr/bin/env ruby
# frozen_string_literal: true

# Temporary comparison. It runs after verification and deletes the collected simulator data.
require 'io/wait'
require 'json'
require 'pty'
require 'rbconfig'
require 'tmpdir'
require 'fileutils'
require 'shellwords'

def stop_group(pid)
  Process.kill('TERM', -pid)
  sleep 1
  Process.kill('KILL', -pid)
rescue Errno::ESRCH
  nil # The diagnostic group has already exited.
end

def stop_reason(parent, deadline)
  return 'parent_exited' if Process.ppid != parent
  return 'time_limit' if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

  nil
end

def copy_available(reader, log)
  log.write(reader.read_nonblock(65_536))
  false
rescue IO::WaitReadable
  reader.wait_readable(0.1)
  false
rescue EOFError, Errno::EIO
  true
end

def drain(reader, log, pid, parent, deadline)
  eof = false
  status = nil
  loop do
    reason = stop_reason(parent, deadline)
    status ||= Process.waitpid2(pid, Process::WNOHANG)&.last
    return [status, reason] if reason || (status && eof)

    if eof
      sleep 0.05
    else
      eof = copy_available(reader, log)
    end
  end
end

def start_command(mode, command)
  return PTY.spawn(command) if mode == 'pty'

  reader, writer = IO.pipe
  pid = Process.spawn(command, in: File::NULL, out: writer, err: writer, pgroup: true)
  [reader, writer, pid]
end

def finish_arm(pid, reader, status, result, result_path)
  stop_group(pid) if pid
  status ||= Process.waitpid2(pid)&.last if pid
  reader&.close
  result.merge!(exit: status&.exitstatus, signal: status&.termsig,
                elapsed: Process.clock_gettime(Process::CLOCK_MONOTONIC) - result.delete(:started))
  File.write(result_path, JSON.pretty_generate(result))
end

def arm(parent:, mode:, limit:, paths:, command:)
  # Stay outside the job group so a cancelled parent cannot bypass this cleanup.
  Process.setsid
  result = { mode: mode, started: Process.clock_gettime(Process::CLOCK_MONOTONIC) }
  reader, writer, pid = start_command(mode, command)
  writer.close
  status, result[:reason] = File.open(paths[:log], 'wb') do |log|
    drain(reader, log, pid, parent, result[:started] + limit)
  end
ensure
  finish_arm(pid, reader, status, result, paths[:result]) if result
end

if ARGV.first == '--arm'
  _, parent, mode, limit, log_path, result_path, command = ARGV
  arm(parent: Integer(parent), mode: mode, limit: Float(limit), paths: { log: log_path, result: result_path }, command: command)
  exit
end

def run_arm(mode, limit, command, directory, name = mode)
  result_path = File.join(directory, "#{name}.json")
  pid = Process.spawn(RbConfig.ruby, __FILE__, '--arm', Process.pid.to_s, mode, limit.to_s,
                      File.join(directory, "#{name}.log"), result_path, command)
  _, status = Process.waitpid2(pid)
  raise "Diagnostic supervisor failed: #{status}" unless status.success?

  JSON.parse(File.read(result_path))
end

def capture(arguments)
  Dir.mktmpdir('woomob-4430-query-') do |temporary|
    stderr = File.join(temporary, 'stderr.log')
    command = "exec #{arguments.shelljoin} </dev/null 2>#{Shellwords.escape(stderr)}"
    result = run_arm('pipe', 10, command, temporary, 'query')
    raise "Diagnostic setup query failed: #{result}" unless result['reason'].nil? && result['exit']&.zero?

    File.read(File.join(temporary, 'query.log'))
  end
end

def simulator_processes
  output = capture(['/bin/ps', '-axo', 'pid=,ppid=,etime=,comm='])
  output.lines.select { |line| File.basename(line.split(nil, 4).last.to_s.strip) == 'simctl' }.map(&:strip)
end

output_dir = File.expand_path('fastlane/test_output/diagnostics-launcher')
FileUtils.mkdir_p(output_dir)
report = { limit_per_arm: 120, arms: [] }
begin
  report[:before] = simulator_processes
  raise 'Existing simctl process; comparison skipped' unless report[:before].empty?

  summary = capture(['/usr/bin/xcrun', 'xcresulttool', 'get', 'test-results', 'summary',
                     '--path', 'fastlane/test_output/WooCommerce.xcresult', '--format', 'json'])
  devices = JSON.parse(summary).fetch('devicesAndConfigurations').map { |item| item.fetch('device').fetch('deviceId') }.uniq
  raise 'Expected one tested simulator' unless devices.size == 1

  udid = devices.first
  raise 'Invalid simulator identifier' unless udid.match?(/\A[0-9A-F-]{36}\z/i)

  report[:device] = udid
  inventory = capture(['/usr/bin/xcrun', 'simctl', 'list', 'devices', '--json'])
  report[:device_state] = JSON.parse(inventory).fetch('devices').values.flatten.find { |device| device['udid'] == udid }&.fetch('state')
  Dir.mktmpdir('woomob-4430-diagnose-') do |temporary|
    %w[pipe pty].each do |mode|
      collected = File.join(temporary, mode)
      command = "exec env NSUnbufferedIO=YES /usr/bin/xcrun simctl diagnose -b --no-archive --udid=#{Shellwords.escape(udid)} --output=#{Shellwords.escape(collected)} </dev/null"
      result = run_arm(mode, 120, command, output_dir)
      result['collected_bytes'] = Dir.glob(File.join(collected, '**', '*')).select { |path| File.file?(path) }.sum { |path| File.size(path) }
      result['top_level_files'] = Dir.exist?(collected) ? Dir.children(collected).sort : []
      result['remaining_simctl'] = simulator_processes
      report[:arms] << result
      FileUtils.rm_rf(collected)
      break unless result['reason'].nil? && result['signal'].nil? && result['exit']&.zero? && result['remaining_simctl'].empty?
    end
  end
rescue StandardError => e
  report[:error] = e.message
ensure
  File.write(File.join(output_dir, 'summary.json'), JSON.pretty_generate(report))
end
