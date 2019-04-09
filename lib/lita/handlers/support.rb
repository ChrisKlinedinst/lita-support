require 'lita'
require 'net/http'
require 'uri'
require 'json'

module Lita
  module Handlers
    class Support < Handler

      config :api_baseurl

      PREFIX = 'support'

      route(
          /^#{PREFIX}\suser\s([0-9]+)/,
          :support_user,
          command: true,
        )

      # callbacks
      def support_user(response)
        unless uid = response['user_id']
          return 'Not found'
        end
        reply_text = "user_id: #{uid}\n"
        reply_text += "email: #{response['email']}\n"
        if (response['name']) then
          reply_text += "name: #{response['name']}\n"
        end
        if (response['company']) then
          reply_text += "company: #{response['company']}\n"
        end
        if (response['plan_name']) then
            reply_text += "plan_name: #{response['plan_name']}\n"
        end
        if (response['mrr']) then
            reply_text += "mrr: #{response['mrr']}\n"
        end
        reply_text += "created_at: #{response['created_at']}\n"
        unless response['deleted_time'] == 0
          reply_text += "deleted_time: #{response['deleted_time']}\n"
        end
        if (response['collaborator_id']) then
          reply_text += "collaborator_id: #{response['collaborator_id']}\n"
          reply_text += "collaborator_email: #{response['collaborator_email']}\n"
        end
        reply_text += "user activity: https://motherbrain.librato.com/billing_reports/top_metrics/#{uid}\n"
        reply_text += "admin: https://admins.appoptics.com/organization/#{uid}\n"

        reply_text
      end

    end

    Lita.register_handler(Support)
  end
end
