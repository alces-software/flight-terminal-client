#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================

class Cluster < ApplicationRecord
  STATUSES = [
    'CREATE_COMPLETE',
    'TERMINATION_IN_PROGRESS',
    'TERMINATION_FAILED',
    'TERMINATION_COMPLETE',
  ].freeze

  scope :using_ongoing_credits, ->() {
    joins(:payment).merge(Payment.using_ongoing_credits)
  }

  scope :running, ->() {
    where.not(status: 'TERMINATION_COMPLETE')
  }

  belongs_to :user
  has_many :compute_queue_actions
  has_many :credit_usages
  has_one :payment

  validates :auth_token,
    length: {maximum: 255},
    presence: true

  validates :status,
    presence: true,
    inclusion: { within: STATUSES }

  before_create do
    credit_usages.build if payment.using_ongoing_credits?
  end

  before_update do
    if status_changed? && status == 'TERMINATION_COMPLETE'
      most_recent_credit_usage = credit_usages.order(:start_at).last
      next if most_recent_credit_usage.nil?
      next unless most_recent_credit_usage.end_at.nil?
      most_recent_credit_usage.end_at = Time.now.utc.to_datetime
      # We need to manually save the credit usage.  It won't be saved with
      # auto association saving due to the way it was loaded from the database
      # (`credit_usages.order(...).last`).  Only associated records loaded
      # with a plain `credit_usages` would be saved by auto association
      # saving.
      saved = most_recent_credit_usage.save(validate: false)
      raise ActiveRecord::Rollback unless saved
    end
  end

  class << self
    # Return attributes suitable for creating a new cluster from the given
    # launch config.
    def attributes_from_launch_config(launch_config)
      hash = HashEmailCommand.new(launch_config.email).perform
      qualified_cluster_name = "#{launch_config.name}-#{hash}"

      {
        cluster_name: launch_config.name,
        qualified_name: qualified_cluster_name,
      }
    end

    # Return attributes suitable for creating a new cluster from the given
    # cluster spec.
    def attributes_from_cluster_spec(cluster_spec)
      {
        domain: domain_from_launch_config(cluster_spec),
      }
    end

    # Return attributes suitable for creating a new cluster from the given fly
    # params.
    def attributes_from_fly_params(fly_params)
      {
        region: region_from_fly_params(fly_params),
      }
    end

    def domain_from_launch_config(cluster_spec)
      domain_arg_found = false
      cluster_spec.args.each do |arg|
        if domain_arg_found
          return arg
        end
        if arg == '--domain' || arg == '-d'
          domain_arg_found = true
        end
      end
      return nil
    end

    def region_from_fly_params(fly_params)
      region = Rails.configuration.alces.default_region
      region_arg_found = false
      fly_params.cmd.each do |arg|
        if region_arg_found
          region = arg
          region_arg_found = false
        end
        if arg == '--region'
          region_arg_found = true
        end
      end
      return region
    end
  end

  def is_running?
    status != 'TERMINATION_COMPLETE'
  end

  def can_terminate?
    ['CREATE_COMPLETE', 'TERMINATION_FAILED'].include?(status)
  end

  def fully_qualified_stack_name
    "#{qualified_name}.#{domain}"
  end
end
