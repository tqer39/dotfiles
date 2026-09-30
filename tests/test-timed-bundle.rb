# frozen_string_literal: true
# cspell:ignore autorun

require 'minitest/autorun'
require 'stringio'
require_relative '../scripts/installers/timed-bundle'

class TimedBundleTest < Minitest::Test
  Entry = Struct.new(:type, :name)

  def test_failure_does_not_hide_output_or_prevent_later_packages
    output = StringIO.new
    installer = Object.new
    calls = []
    installer.define_singleton_method(:install!) do |entries, **options|
      name = entries.fetch(0).name
      calls << [name, options]
      # The start marker must be visible before the installer returns.
      raise 'missing start marker' unless output.string.include?("[START] cask #{name}")
      raise 'permission denied' if name == 'broken'

      name != 'failure'
    end
    entries = %w[broken failure working].map { |name| Entry.new(:cask, name) }
    refute TimedBundle.run(entries, installer, no_upgrade: true, output: output)
    assert_equal %w[broken failure working], calls.map(&:first)
    assert calls.all? { |_, options| options == { no_upgrade: true, verbose: true } }
    assert_includes output.string, '[ERROR] cask broken: permission denied'
    assert_includes output.string, '[FAILED] cask failure'
    assert_includes output.string, '[OK] cask working'
    assert_equal 3, output.string.lines.count { |line| line.start_with?('[TIME]') }
  end

  def test_silent_command_has_progress_and_elapsed_time
    output = StringIO.new
    success, elapsed = TimedBundle.measure('silent app', interval: 0.01, output: output) do
      sleep 0.06
      true
    end
    assert success
    assert_operator elapsed, :>=, 0.06
    assert_includes output.string, '[RUNNING] silent app'
    assert_includes output.string, '[OK] silent app'
    snapshot = output.string.dup
    sleep 0.03
    assert_equal snapshot, output.string
  end

  def test_interrupt_propagates_and_stops_heartbeat
    output = StringIO.new
    assert_raises(Interrupt) do
      TimedBundle.measure('interrupted', interval: 0.01, output: output) { raise Interrupt }
    end
    assert_includes output.string, '[FAILED] interrupted'
    snapshot = output.string.dup
    sleep 0.03
    assert_equal snapshot, output.string
  end
end
