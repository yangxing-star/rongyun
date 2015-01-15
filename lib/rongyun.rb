require "rongyun/version"

require 'digest/sha1'
require 'net/https'
require 'uri'
require 'json'

module Rongyun
  # Your code goes here...
  #
  class Client
    ACTION_USER_TOKEN = "/user/getToken"
    ACTION_MESSAGE_PUBLISH = "/message/publish"
    ACTION_MESSAGE_SYSTEM_PUBLISH = "/message/system/publish"
    ACTION_MESSAGE_GROUP_PUBLISH = "/message/group/publish"
    ACTION_MESSAGE_CHATROOM_PUBLISH = "/message/chatroom/publish"
    ACTION_GROUP_SYNC = "/group/sync"
    ACTION_GROUP_CREATE = "/group/create"
    ACTION_GROUP_JOIN = "/group/join"
    ACTION_GROUP_QUIT = "/group/quit"
    ACTION_GROUP_DISMISS = "/group/dismiss"
    ACTION_CHATROOM_CREATE = "/chatroom/create"
    ACTION_CHATROOM_DESTROY = "/chatroom/destroy"
    ACTION_CHATROOM_QUERY = "/chatroom/query"

    def initialize app_key    = nil,
                   app_secret = nil,
                   verify     = true
      @version       = 1.0

      @api_host      = "https://api.cn.rong.io"
      @response_type = "json"
      @user_agent    = "RongCloudSdk/RongCloud-Ruby-Sdk #{RUBY_VERSION} (#{@version})"

      @app_key       = app_key     || @app_key    = ENV["rongcloud-app-key"]
      @app_secret    = app_secret  || @app_secret = ENV["rongcloud-app-secret"]
      @verify        = verify
    end

    def make_signature
      nonce     = "#{Random.new(Time.now.to_i).rand(100000000000000)}"
      timestamp = "#{Time.now.to_i}"
      signature = Digest::SHA1.hexdigest(@app_secret + nonce + timestamp)

      {
        "app-key"   => @app_key,
        "nonce"     => nonce,
        "timestamp" => timestamp,
        "signature" => signature
      }
    end

    def headers
      header = { "content-type" => "application/x-www-form-urlencoded",
                 "user-agent"   => @user_agent}
      header.merge!(make_signature)
    end

    def http_call url,
                  http_headers,
                  data
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")        # enable SSL/TLS
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  #这个也很重要

      req = Net::HTTP::Post.new(uri.path, initheader = http_headers)
      req.body = URI.encode_www_form(data)
      res = http.request(req)
      handle_response(res)
    end

    def handle_response response
      status = response.code.to_i
      case status
        when 200..299 then
          JSON.parse(response.body)
        else
          raise Exception, "Response #{response.code} #{response.message}: #{response.body}"
      end
    end

    def post action,
             params = nil
      http_call(@api_host + action + "." + @response_type, headers, params)
    end

    def user_get_token user_id,
                       name,
                       portrait_uri
      post(
        action=ACTION_USER_TOKEN,
        params={
          "userId"      => user_id,
          "name"        => name,
          "portraitUri" => portrait_uri
        })
    end

    def message_publish from_user_id,
                        to_user_id,
                        object_name,
                        content,
                        push_content = nil,
                        push_data    = nil
      post(
        action=ACTION_MESSAGE_PUBLISH,
        params={
          "fromUserId"  => from_user_id,
          "toUserId"    => to_user_id,
          "objectName"  => object_name,
          "content"     => content,
          "pushContent" => push_content.nil? ? "" : push_content,
          "pushData"    => push_data.nil? ? "" : push_data
        })
    end

    def message_system_publish from_user_id,
                               to_user_id,
                               object_name,
                               content,
                               push_content = nil,
                               push_data    = nil
      post(
        action=ACTION_MESSAGE_SYSTEM_PUBLISH,
        params={
          "fromUserId"  => from_user_id,
          "toUserId"    => to_user_id,
          "objectName"  => object_name,
          "content"     => content,
          "pushContent" => push_content.nil? ? "" : push_content,
          "pushData"    => push_data.nil? ? "" : push_data
        })
    end

    def message_group_publish from_user_id,
                              to_group_id,
                              object_name,
                              content,
                              push_content = nil,
                              push_data    = nil
      post(
        action=ACTION_MESSAGE_GROUP_PUBLISH,
        params={
          "fromUserId"  => from_user_id,
          "toGroupId"   => to_group_id,
          "objectName"  => object_name,
          "content"     => content,
          "pushContent" => push_content.nil? ? "" : push_content,
          "pushData"    => push_data.nil? ? "" : push_data
        })
    end

    def message_chatroom_publish from_user_id,
                                 to_chatroom_id,
                                 object_name,
                                 content
      post(
        action=ACTION_MESSAGE_GROUP_PUBLISH,
        params={
          "fromUserId" => from_user_id,
          "toGroupId"  => to_chatroom_id,
          "objectName" => object_name,
          "content"    => content
        })
    end

    def group_sync user_id,
                   groups
      groups.each { |k, v|
        group_mapping["group[#{k}]"] = v
      }
      group_mapping["userId"] = user_id

      post(
        action=ACTION_GROUP_SYNC,
        params=group_mapping)
    end

    def group_create user_id_list,
                     group_id,
                     group_name
      post(
        action=ACTION_GROUP_CREATE,
        params={
          "userId"    => user_id_list,
          "groupId"   => group_id,
          "groupName" => group_name
        })
    end

    def group_join user_id_list,
                   group_id,
                   group_name
        post(
            action=ACTION_GROUP_JOIN,
            params={
                "userId"    => user_id_list,
                "groupId"   => group_id,
                "groupName" => group_name
            })
    end

    def group_quit user_id_list,
                   group_id
      post(
        action=ACTION_GROUP_QUIT,
        params={
          "userId"    => user_id_list,
          "groupId"   => group_id
        })
    end

    def group_dismiss user_id,
                      group_id
      post(
        action=ACTION_GROUP_DISMISS,
        params={
          "userId"  => user_id,
          "groupId" => group_id,
        })
    end

    def chatroom_create chatrooms
      chatrooms.each { |k, v|
        chatroom_mapping["charoom[#{k}]"] = v
      }

      post(
        action=ACTION_CHATROOM_CREATE,
        params=chatroom_mapping)
    end

    def chatroom_destroy chatroom_id_list=nil
      post(
        action=ACTION_CHATROOM_DESTROY,
        params={
          "chatroomId" => chatroom_id_list.nil? ? [] : chatroom_id_list
        })
    end

    def chatroom_query chatroom_id_list=nil
      post(
        action=ACTION_CHATROOM_QUERY,
        params={
          "chatroomId" => chatroom_id_list.nil? ? [] : chatroom_id_list
        })
    end
  end
end
