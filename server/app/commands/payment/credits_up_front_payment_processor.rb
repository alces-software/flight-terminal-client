#==============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================

module Payment
  class CreditsUpFrontPaymentProcessor < ProcessPaymentCommand
    def about_to_queue
    end

    def queue_failed
    end

    def about_to_launch
      @payment.user.compute_credits -= @payment.required_credits
      @payment.user.save!
      @credits_subtracted = true
    end

    def launch_failed
      return unless @credits_subtracted
      @payment.user.compute_credits += @payment.required_credits
      begin
        @payment.user.save!
      rescue
        user = @payment.user
        Alces.app.logger.warn(
          "Failed to credit #{user.id}:#{user.email} with " +
          "#{@payment.required_credits} credits"
        ) { $!.message }
        raise
      end
    end

    def launch_succeeded
    end
  end
end
