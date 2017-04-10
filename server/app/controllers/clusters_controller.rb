#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================

class ClustersController < ApplicationController
  def launch
    cluster_launch_config = build_launch_config

    if cluster_launch_config.invalid?
      render status: :unprocessable_entity, json: {
        status: 422,
        error: 'Unprocessable Entity',
        details: cluster_launch_config.errors.messages
      }
      return
    end

    launch_command = LaunchClusterCommand.new(cluster_launch_config)
    begin
      launch_command.perform
    rescue LaunchClusterCommand::LaunchError
      Rails.logger.info("Launching cluster failed: #{$!.message}")
      render_exception($!)
    else
      if cluster_launch_config.using_token?
        arn = nil
        cf_url = nil
      else
        arn = launch_command.arn
        cf_url = cloudformation_url(arn, cluster_launch_config)
      end
      render(
        json: {
          arn: arn,
          cloudformation_url: cf_url,
          cluster_name: cluster_launch_config.name,
          email: cluster_launch_config.email,
        },
        status: :accepted
      )
    end
  end

  private

  def build_launch_config
    cluster_spec = ClusterSpec.new(cluster_spec_params)
    config_params = cluster_launch_config_params.merge(spec: cluster_spec)
    ClusterLaunchConfig.new(config_params)
  end

  def cluster_spec_params
    params.require(:fly).permit(args: []).tap do |h|
      unless params[:fly][:parameterDirectoryOverrides].nil?
        h[:parameter_directory_overrides] = params[:fly][:parameterDirectoryOverrides].permit!
      end
    end
  end

  def cluster_launch_config_params
    permitted_params = [:email, :name, :access_key, :secret_key, :token, :region, :key_pair]
    required_params = [:email, :name]

    params.require(:cluster).permit(*permitted_params).tap do |h|
      required_params.each {|p| h.require(p) }
    end
  end

  def cloudformation_url(arn, cluster_launch_config)
    if cluster_launch_config.region.present?
      region = "#{cluster_launch_config.region}."
    end
    "https://#{region}console.aws.amazon.com/cloudformation/home#/stack/detail?stackId=#{arn}"
  end

  def render_exception(exc)
    case exc
    when LaunchClusterCommand::ArnNotAvailable
      render status: :gateway_timeout, json: {
        status: 504,
        error: 'Gateway Timeout'
      }
      return
    when LaunchClusterCommand::InvalidKeyPair
      details = {
        key_pair: ['invalid key pair name']
      }
    when LaunchClusterCommand::InvalidCredentials
      details = {
        credentials: ['invalid credentials']
      }
    when LaunchClusterCommand::BadRegion
      details = {
        region: ['bad region']
      }
    when LaunchClusterCommand::ClusterNameTaken
      details = {
        cluster_name: ['taken']
      }
    else
      raise exc
    end

    render status: :unprocessable_entity, json: {
      status: 422,
      error: 'Unprocessable Entity',
      details: details
    }
  end
end
