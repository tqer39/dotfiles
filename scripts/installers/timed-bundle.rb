# frozen_string_literal: true

# Run with `brew ruby` so Brewfile evaluation and install/upgrade/skip semantics
# come from the installed Homebrew, including OS and work-mode conditionals.
module TimedBundle
  def self.measure(label, interval: 30, output: $stdout)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    output.puts "[START] #{label}"
    heartbeat = Thread.new do
      loop do
        sleep interval
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        output.puts format('[RUNNING] %s %.1fs', label, elapsed)
      end
    end
    success = false
    begin
      success = yield
    rescue StandardError => e
      output.puts "[ERROR] #{label}: #{e.message}"
    ensure
      heartbeat.kill
      heartbeat.join
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      output.puts format('[%s] %s %.1fs', success ? 'OK' : 'FAILED', label, elapsed)
    end
    [success, elapsed]
  end

  def self.run(entries, installer, no_upgrade: false, output: $stdout, interval: 30)
    results = entries.map do |entry|
      label = "#{entry.type} #{entry.name}"
      success, elapsed = measure(label, interval: interval, output: output) do
        installer.install!([entry], no_upgrade: no_upgrade, verbose: true)
      end
      [label, success, elapsed]
    end
    output.puts '[SUMMARY] Package processing time, slowest first (includes checks and dependencies)'
    results.sort_by { |_, _, elapsed| -elapsed }.each do |label, success, elapsed|
      output.puts format('[TIME] %8.1fs %-6s %s', elapsed, success ? 'OK' : 'FAILED', label)
    end
    results.all? { |_, success, _| success }
  end
end

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true
  $stderr.sync = true
  require 'bundle'
  require 'bundle/brewfile'
  require 'bundle/installer'

  dsl = Homebrew::Bundle::Brewfile.read(file: ARGV.fetch(0))
  # Taps must be available before formulae are processed.
  entries = dsl.entries.sort_by { |entry| entry.type == :tap ? 0 : 1 }
  success = TimedBundle.run(entries, Homebrew::Bundle::Installer,
                            no_upgrade: !ENV.fetch('HOMEBREW_BUNDLE_NO_UPGRADE', '').empty?)
  Homebrew::Bundle.mark_as_installed_on_request!(dsl.entries)
  exit(success ? 0 : 1)
end
