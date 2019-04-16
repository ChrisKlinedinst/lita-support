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
          /^#{PREFIX}\suser\s+-/,
          :lookup_user,
          command: true,
          kwargs: {
            alert_id: {
              short: "a"
            },
            dashboard_id: {
              short: "d"
            },
            email: {
              short: "e"
            },
            instrument_id: {
              short: "i"
            },
            metric_id: {
              short: "m"
            },
            organization_id: {
              short: "u"
            },
            stream_id: {
              short: "s"
            },
            space_id: {
              short: "c"
            },
            url: {},
            env: {
              default: "production"
            },
            verbose: {
              short: "v",
              boolean: false
            }
          }
        )

      # callbacks
      def lookup_user(act)

        act.reply act.extensions[:kwargs]

        param_count = 0
        param_key = nil
        param_value = nil
        act.extensions[:kwargs].each do |key, value|
          unless (['verbose','env'].include?(key.to_s) || value == nil) then
            param_key = key.to_s
            param_value = value
            param_count += 1
          end
        end

        if (param_count != 1) then
          act.reply "Please use exactly one user search criteria, such as organization_id, metric_id, alert_id, etc. (env and verbose flags are not search criteria)"
          act.reply "Arguments you used: #{act.extensions[:kwargs]}"
          return nil
        end

        environment = act.extensions[:kwargs][:env]
        verbose = (act.extensions[:kwargs][:verbose]) ? true : false

        # Slack auto formats email addresses to <mailto:email|email>.
        if param_key == 'email'
          param_value.gsub!(/.*mailto:([^\|]+).*/, '\1')
        end

        begin
          uri = URI.parse("#{config.api_baseurl}/api?#{param_key}=#{param_value}")
          response = Net::HTTP.get_response(uri)
          result = JSON.parse(response.body)
          act.reply '```' + format_user(result) + '```'
        rescue Exception => e
          act.reply '```' + "Exception: #{e}" + '```'
          act.reply "uri: #{uri}"
        end

      end

      #response
      def reply_with_user(act, param, value)
        response = API.get("#{config.api_baseurl}/api", "#{param}=#{value}")
        act.reply "```#{format_user(response)}```"
      end

      def format_user(response)
        unless uid = response['user_id']
          return 'Not found'
        end
        reply_text = "organization_id: #{uid}\n"
        reply_text += "email: #{response['email']}\n"
        if (response['name']) then
          reply_text += "name: #{response['name']}\n"
        end
        if (response['swicus_id']) then
          reply_text += "swicus_id: #{response['swicus_id']}\n"
        end
        if (response['company']) then
          reply_text += "company: #{response['company']}\n"
        end
        if (response['plan_name']) then
          reply_text += "plan_name: #{response['plan_name']}\n"
        end
        if (response['members']) then
          reply_text += "members: #{response['members']}\n"
        end
        if (response['mrr']) then
          reply_text += "mrr: #{response['mrr']}\n"
        end
        if (response['balance']) then
          reply_text += "balance: #{response['balance']}\n"
        end
        if (response['coupon']) then
          reply_text += "coupon: #{response['coupon']}\n"
        end
        reply_text += "created_at: #{response['created_at']}\n"
        if (response['collaborator_id']) then
          reply_text += "collaborator_id: #{response['collaborator_id']}\n"
          reply_text += "collaborator_email: #{response['collaborator_email']}\n"
        end
        reply_text += "user activity: https://motherbrain.librato.com/billing_reports/top_metrics/#{uid}\n"
        reply_text += "admin: https://admins.appoptics.com/organization/#{uid}"

        reply_text
      end

    end
    Lita.register_handler(Support)
  end
end
