require 'lita'
require 'net/http'
require 'uri'
require 'json'

module Lita
  module Handlers
    class Support < Handler

      # LOOKUP!
      #        __         __
      #       /.-'       `-.\
      #      //             \\
      #     /j_______________j\
      #    /o.-==-. .-. .-==-.o\
      #    ||      )) ((      ||
      #     \\____//   \\____//   hjw
      #      `-==-'     `-==-'

      config :api_baseurl
      config :api_user
      config :api_pass



      PREFIX = 'support'

      route(
          /^#{PREFIX}.*help$/,
          :showhelp,
          command: true,
          :help => { "support help" => 'output help to user privately' }
        )

      route(
          /^#{PREFIX}\suser\s+-/,
          :support_user,
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
            user_id: {
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

      route(
          /^#{PREFIX}\suser\s<(https[^>]+)/,
          :find_by_url,
          command: true,
          kwargs: {
            env: {
              default: "production"
            }
          }
        )

      route(
          /^#{PREFIX}\suser\s(https\S+)/i,
          :find_by_url,
          command: true,
          kwargs: {
            env: {
              default: "production"
            }
          }
        )

      route(
          /^#{PREFIX}\suser\s([0-9]+)/,
          :find_by_user,
          command: true,
          kwargs: {
            env: {
              default: "production"
            }
          }
        )

      route(
          /^#{PREFIX}\suser\s<mailto:([^\|]+)/,
          :find_by_email,
          command: true,
          kwargs: {
            env: {
              default: "production"
            }
          }
        )

      route(
          /^#{PREFIX}\suser\s(\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b)/i,
          :find_by_email,
          command: true,
          kwargs: {
            env: {
              default: "production"
            }
          }
        )

      route(
          /^#{PREFIX}\shost\s+(\S+)/,
          :support_host,
          command: true,
          kwargs: {
            env: {
              default: "production"
            }
          }
        )

      route(
          /^#{PREFIX}\sprs\s+(\S+)/,
          :support_prs,
          command: true,
        )

      # callbacks

      def find_by_url(act)
        info = UrlParser.parse(act.matches.flatten.first)
        if info[:errors].empty?
          reply_with_user(act, info[:type], info[:id])
        else
          act.reply "```#{info[:errors].join("\n")}```"
        end
      end

      def find_by_user(act)
        reply_with_user(act, 'organization_id', act.matches.flatten.first)
      end

      def find_by_email(act)
        reply_with_user(act, 'email', act.matches.flatten.first)
      end

      def support_user(act)

        :api_baseurl.authenticate(config.api_user, config.api_pass)
        conn = :api_baseurl.connection

        act.reply act.extensions[:kwargs]

        param_count = 0
        param_key = nil
        param_value = nil
        act.extensions[:kwargs].each do |key, value|
          unless (['verbose','env'].include?(key.to_s) || value == nil) then
            param_key = "organization_id"
            param_value = value
            param_count += 1
          end
        end

        if (param_count != 1) then
          act.reply "Please use exactly one user search criteria, such as user_id, metric_id, alert_id, etc. (env and verbose flags are not search criteria)"
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
          uri = URI.parse("#{config.api_baseurl}/api", "#{param_key}=#{param_value}")
          response = Net::HTTP.get_response(uri)
          result = JSON.parse(response.body)
          act.reply '```' + format_user(result) + '```'
        rescue Exception => e
          act.reply '```' + "Exception: #{e}" + '```'
          act.reply "uri: #{uri}"
        end

      end

      def lookup_host(act)

        # environment not yet implemented in ops api; defaults to production
        environment = act.extensions[:kwargs][:env]
        identifier = act.matches.flatten.first
        response = API.get("#{config.api_baseurl}/lookup/host", "identifier=#{identifier}")
        act.reply '```' + format_host(response) + '```'

      end

      def lookup_prs(act)
        identifier = act.matches.flatten.first
        # its either this or rename the Github group
        identifier = 'Ops' if identifier == 'ops'
        response = API.get("#{config.api_baseurl}/github/prs", "team=#{identifier}")
        act.reply "_Outstanding #{identifier} Pull Requests_\n" + format_prs(response)
      end

      # helpers

      def reply_with_user(act, param, value)
        response = API.get("#{config.api_baseurl}/api", "#{param}=#{value}")
        act.reply "```#{format_user(response)}```"
      end

      def format_user(response)
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

      def format_host(response)
        unless response['Name']
          return 'Host not found'
        end
        reply_text = "Name: #{response['Name']}\n"
        reply_text += "instance_id: #{response['instance_id']}\n"
        reply_text += "instance_type: #{response['instance_type']}\n"
        reply_text += "placement: #{response['placement']}\n"
        reply_text += "private_ip_address: #{response['private_ip_address']}\n"
        reply_text += "launch_time: #{response['launch_time']}\n"
        reply_text += "state: #{response['state']}"
      end

      def format_prs(response)
        reply_text= String.new
        # lita does some weird stuff to our data structure inserting the statuscode
        response.each do |returned|
             next if (returned.first == 'status')
             reply_text += "*#{returned.first}*\n"
             returned[1].each do | repoline |
               reply_text += repoline + "\n"
             end
        end
        return reply_text
      end


      def showhelp(act)
        act.reply "Lookup Commands: help sent privately to requesting user"

        helptext = <<EOS
I support the following lookup commands:
(Environment always defaults to production)

*Find open Github Pull Requests for a Librato team*
```
lita #{PREFIX} prs data
```

`lita #{PREFIX} host` <identifier>

*Find an EC2 host by instance_id*
```
lita #{PREFIX} host i-008f362d
```
*Find an EC2 host by ip*
```
lita #{PREFIX} host 10.237.207.244
```

`lita #{PREFIX} user` options

*Find a Librato user by id.*
```
lita #{PREFIX} user 1
```

*Find a Librato user by email.*
```
lita #{PREFIX} user foo@example.com
```

*Find a Librato user by url.*
```
lita #{PREFIX} user https://metrics.librato.com/s/spaces/1
lita #{PREFIX} user https://metrics.librato.com/dashboards/1
lita #{PREFIX} user https://metrics.librato.com/instruments/1
```

Other options

```
> lita #{PREFIX} user (search_option) [--env [staging|production]] [--verbose | -v]

Find a Librato user by one (and only one) of several search options.

search_option can be one of the following unique identifiers:

[-u |       --user_id ]  <user_id>
[-a |      --alert_id ]  <alert_id>
[-d |  --dashboard_id ]  <dashboard_id>
[-e |         --email ]  <smtp_email_address>
[-i | --instrument_id ]  <instrument_id>
[-m |     --metric_id ]  <metric_id>
[-s |     --stream_id ]  <stream_id>
[-c |      --space_id ]  <space_id>
```
EOS
        act.reply_privately helptext

      end

    end

    Lita.register_handler(Support)
  end
end
