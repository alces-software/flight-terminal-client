#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================

class ClustersController < ApplicationController
  class TokenNotFound < RuntimeError ; end

  def launch
    build_models
    return if @cluster_launch_config.nil?

    payment_invalid = @payment.invalid?(:queue)
    if @cluster_launch_config.invalid? || payment_invalid
      errors = @cluster_launch_config.errors.messages
      errors.merge!(payment: @payment.errors.messages) if payment_invalid
      render status: :unprocessable_entity, json: {
        status: 422,
        error: 'Unprocessable Entity',
        details: errors
      }
      return
    end

    payment_processor = ProcessPaymentCommand.load(@payment, @cluster_launch_config.email)
    begin
      payment_processor.process_about_to_queue
      ClusterLaunchJob.perform_later(
        launch_config_params: @cluster_launch_config.as_json,
        cluster_spec_params: @cluster_spec.as_json,
        tenant: @tenant,
        payment_params: @payment.as_json,
        launch_option_params: @launch_option.as_json,
      )
    rescue
      Rails.logger.warn("Queueing cluster launch failed: #{$!.message}")
      payment_processor.process_queue_failed
      raise
    end

    render(
      json: {
        cluster_name: @cluster_launch_config.name,
        email: @cluster_launch_config.email,
      },
      status: :accepted
    )
  end

  def terminate
    cluster = Cluster.find(params[:id])
    unless cluster.can_terminate?
      render status: :unacceptable
      return
    end
    TerminateClusterJob.perform_later(cluster)
    render status: :accepted
  end

  private

  def build_models
    @tenant = Tenant.find_by!(params.require(:tenant).permit(:identifier))
    @cluster_spec = ClusterSpec.load(cluster_spec_params, @tenant, current_user)
    @launch_option = LaunchOption.new(launch_option_params(@cluster_spec))
    @payment = Payment.new(payment_params(@cluster_spec, @launch_option))
    @payment.token = find_token(@tenant) if @payment.using_token?
    @cluster_launch_config = ClusterLaunchConfig.new(cluster_launch_config_params)
  rescue ClusterSpec::Error, TokenNotFound
    render_build_exception($!)
    return nil
  end

  def payment_params(cluster_spec, launch_option)
    permitted_params = [
      :maxCreditUsage,
      :paymentMethod,
      :runtime,
    ]
    params.require(:payment).permit(*permitted_params).tap do |h|
      h.require(:paymentMethod)
      h['max_credit_usage'] = h.delete('maxCreditUsage') if h.key?('maxCreditUsage')
      h['payment_method'] = h.delete('paymentMethod') if h.key?('paymentMethod')
      h['user'] = current_user
    end.merge(
      cluster_spec: @cluster_spec,
      upfront_cost_per_hour: @launch_option.upfront_cost_per_hour,
      master_node_cost_per_hour: @launch_option.master_node_cost_per_hour,
    )
  end

  def cluster_spec_params
    params.require(:clusterSpec).permit(:file, :name).tap do |h|
      h.require(:file)
      h.require(:name)
    end
  end

  def cluster_launch_config_params
    queue_params = (params[:clusterLaunch] || {})[:queues] || {}
    permitted_queues = queue_params.keys.each_with_object({}) do |q, h|
      h[q] = [:desired, :min, :max]
    end
    permitted_params = [
      :collection,
      :email,
      :key_pair,
      :name,
      :region,
      queues: permitted_queues
    ]
    required_params = [:email, :name]

    params.require(:clusterLaunch).permit(*permitted_params).tap do |h|
      required_params.each {|p| h.require(p) }
    end
  end

  def launch_option_params(cluster_spec)
    selected_index = params.require(:launchOption).require(:index)
    launch_option_from_spec = cluster_spec.selected_launch_option(selected_index)
    launch_option_from_spec.tap do |h|
      h['charging_model'] = h.delete('chargingModel') if h.key?('chargingModel')
      h.delete('costPerHour') if h.key?('costPerHour')
    end
  end

  def find_token(tenant)
    tenant.tokens.find_by(params.require(:token).permit(:name)).tap do |token|
      raise TokenNotFound if token.nil?
    end
  end

  def render_build_exception(exc)
    case exc
    when ClusterSpec::ClusterSpecNotFound
      render status: :unprocessable_entity, json: {
        status: 422,
        error: 'Unprocessable Entity',
        details: {
          cluster_spec: ["spec not found"],
        }
      }
    when ClusterSpec::ClusterSpecNotAuthorized
      render status: :forbidden, json: {
        status: 403,
        error: 'Forbidden',
        details: {
          cluster_spec: ["spec not authorized"],
        }
      }
    when ClusterSpec::ClusterSpecsNotValid
      render status: :internal_server_error, json: {
        status: 500,
        error: 'Internal Server Error',
        details: {
          cluster_spec: ["spec not valid"],
        }
      }
    when ClusterSpec::UnableToRetrieveClusterSpecs
      render status: :bad_gateway, json: {
        status: 502,
        error: 'Bad Gateway',
        details: {
          cluster_spec: ["unable to retrieve cluster specs - #{$!.message}"],
        }
      }
    when TokenNotFound
      render status: :unprocessable_entity, json: {
        status: 422,
        error: 'Unprocessable Entity',
        details: {
          token: ["token not found"],
        }
      }
    end
  end
end
