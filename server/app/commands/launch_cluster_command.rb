#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================

require 'tmpdir'

#
# Orchestrate the launching a cluster via Flight Attendant.
#
# An overview of the launch process is:
#
#  1. Have `fly` build a new parameter directory.
#
#  2. Merge in any overrides present in `@launch_config.spec`.
#
#  3. Run the `fly cluster launch` command in a background thread, using the
#     correct parameter directory.
#
#  4. Block until the arn is available for the stack (or the command has
#     failed) and then return control to the caller.
#
#  5. In the background thread, when the fly launch command has completed,
#     send an email to that affect.
#
class LaunchClusterCommand
  class LaunchFailed < RuntimeError; end

  attr_reader :launch_thread

  delegate :arn, :stdout, :stderr, to: :@run_fly_cmd

  def initialize(launch_config)
    @launch_config = launch_config
  end

  def perform
    Rails.logger.info("Launching cluster #{@launch_config.name} " +
                      "with spec #{@launch_config.spec.inspect}")

    BuildParameterDirectoryCommand.new(parameter_dir, @launch_config.spec).
      perform
    @run_fly_cmd = RunFlyLaunchCommand.new(parameter_dir, @launch_config)

    send_about_to_launch_email
    run_launch_thread
    wait_for_arn

    if @run_fly_cmd.failed?
      # No need to send a failed email here.  One will be sent when
      # @launch_thread terminates.
      raise LaunchFailed, @run_fly_cmd.stderr
    else
      send_launching_email
    end
  ensure
    FileUtils.rm_r(parameter_dir, secure: true)
  end

  def run_launch_thread
    # Launch the cluster in the background.  It will take a while and we want
    # to report back to the user as soon as we can.
    @launch_thread = Thread.new do
      begin
        @run_fly_cmd.perform
      rescue
        send_failed_email
        Rails.logger.info "Launch thread raised exception #{$!}"
        raise LaunchFailed, "Launch thread failed: #{$!}"
      else
        if @run_fly_cmd.failed?
          send_failed_email
        else
          send_completed_email
        end
      end
    end
  end

  def wait_for_arn
    # Wait until the arn is available.  The arn is needed to point the user at
    # the cloudformation console page for the stack.
    max_wait = Rails.configuration.alces.wait_for_arn_duration
    slept = 0
    while @run_fly_cmd.waiting_for_arn?
      Rails.logger.debug("Waiting for stack arn to become available. " +
                         "Waited #{slept} of max #{max_wait} seconds.")
      if slept > max_wait
        raise LaunchFailed,
          "arn not available after #{count} seconds\n#{@run_fly_cmd.stderr}"
      end
      unless @launch_thread.alive?
        raise LaunchFailed,
          "Launch thread no longer running: #{@run_fly_cmd.stderr}"
      end
      sleep 1
      slept += 1
    end
    if arn.present?
      Rails.logger.info "Stack arn available after #{slept} seconds: #{arn}"
    else
      Rails.logger.info "Stack arn not available. fly command no longer waiting for arn."
    end
  end

  # Get a tmpdir name, without creating the directory.
  def parameter_dir
    @parameter_dir ||= File.join(
      Dir.tmpdir,
      Dir::Tmpname.make_tmpname('flight-launch-', nil)
    )
  end

  def send_about_to_launch_email
    ClustersMailer.about_to_launch(@launch_config).
      deliver_now
  end

  def send_launching_email
    ClustersMailer.launching(@launch_config, arn).
      deliver_now
  end

  def send_failed_email
    ClustersMailer.failed(@launch_config, @run_fly_cmd.stderr, arn).
      deliver_now
  end

  def send_completed_email
    ClustersMailer.launched(@launch_config, @run_fly_cmd.stdout).
      deliver_now
  end
end