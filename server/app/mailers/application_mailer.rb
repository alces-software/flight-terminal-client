#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Flight Ltd.
#
# This file is part of Alces Launch.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
require_dependency 'alces/mailer/resender'
require_dependency 'alces/action_view/templates'

class ApplicationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  extend Alces::Mailer::Resender

  layout 'mailer'
  helper 'mailer'

  default from: 'Flight Launch <launch@alces-flight.com>',
    reply_to: 'Nobody <no-reply@alces-flight.com>',
    bcc: ENV['MAIL_BCC_ADDRESS']
end
