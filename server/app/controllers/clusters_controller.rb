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
    return if cluster_launch_config.nil?

    if cluster_launch_config.invalid?
      render status: :unprocessable_entity, json: {
        status: 422,
        error: 'Unprocessable Entity',
        details: cluster_launch_config.errors.messages
      }
      return
    end

    # XXX What errors can be raised here?  Queue connection errors.  Any
    # others.
    ClusterLaunchJob.perform_later(
      cluster_launch_config.as_json,
      cluster_launch_config.spec.as_json
    )

    render(
      json: {
        cluster_name: cluster_launch_config.name,
        email: cluster_launch_config.email,
      },
      status: :accepted
    )
  end

  private

  def build_launch_config
    cluster_spec = ClusterSpec.load(cluster_spec_params)
    config_params = cluster_launch_config_params.merge(spec: cluster_spec)
    ClusterLaunchConfig.new(config_params)
  rescue ClusterSpec::Error
    render_build_exception($!)
    return nil
  end

  def cluster_spec_params
    params.require(:clusterSpec).permit(:file, :name).tap do |h|
      h.require(:file)
      h.require(:name)
    end
  end

  def cluster_launch_config_params
    permitted_params = [:email, :name, :token, :region, :key_pair]
    required_params = [:email, :name]

    params.require(:clusterLaunch).permit(*permitted_params).tap do |h|
      required_params.each {|p| h.require(p) }
    end
  end

  def render_exception(exc)
    case exc
    when LaunchClusterCommand::InvalidKeyPair
      details = {
        key_pair: ['invalid key pair name']
      }
    when LaunchClusterCommand::InvalidCredentials
      # XXX Is this one possible?
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

  def render_build_exception(exc)
    case exc
    when ClusterSpec::ClusterSpecNotFound
      render status: :unprocessable_entity, json: {
        status: 422,
        error: 'Unprocessable Entity',
        details: "Cluster spec not found"
      }
    when ClusterSpec::ClusterSpecsNotValid
      render status: :internal_server_error, json: {
        status: 500,
        error: 'Internal Server Error',
        details: "Cluster specs not valid"
      }
    when ClusterSpec::UnableToRetrieveClusterSpecs
      render status: :bad_gateway, json: {
        status: 502,
        error: 'Bad Gateway',
        details: "Unable to retrieve cluster specs - #{$!.message}"
      }
    end
  end
end
