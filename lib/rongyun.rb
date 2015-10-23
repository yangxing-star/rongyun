require 'rongyun/version'

require 'digest/sha1'
require 'net/https'
require 'uri'
require 'json'

module Rongyun
  # Your code goes here...
  #
  class Client

    ACTION_USER_TOKEN = '/user/getToken'
    ACTION_MESSAGE_PUBLISH = '/message/private/publish'
    ACTION_MESSAGE_SYSTEM_PUBLISH = '/message/system/publish'
    ACTION_MESSAGE_GROUP_PUBLISH = '/message/group/publish'
    ACTION_MESSAGE_CHATROOM_PUBLISH = '/message/chatroom/publish'
    ACTION_MESSAGE_BROADCAST = '/message/broadcast'
    ACTION_GROUP_SYNC = '/group/sync'
    ACTION_GROUP_CREATE = '/group/create'
    ACTION_GROUP_JOIN = '/group/join'
    ACTION_GROUP_QUIT = '/group/quit'
    ACTION_GROUP_DISMISS = '/group/dismiss'
    ACTION_CHATROOM_CREATE = '/chatroom/create'
    ACTION_CHATROOM_DESTROY = '/chatroom/destroy'
    ACTION_CHATROOM_QUERY = '/chatroom/query'
    ACTION_USER_BLACKLIST_ADD = '/user/blacklist/add'
    ACTION_USER_BLACKLIST_REMOVE = '/user/blacklist/remove'

    def initialize app_key    = nil,
                   app_secret = nil,
                   verify     = true
      @version       = 1.0

      @api_host      = 'https://api.cn.rong.io'
      @response_type = 'json'
      @user_agent    = "RongCloudSdk/RongCloud-Ruby-Sdk #{RUBY_VERSION} (#{@version})"

      @app_key       = app_key || ENV['rongcloud_app_key']
      @app_secret    = app_secret || ENV['rongcloud_app_secret']
      @verify        = verify
    end

    def make_signature
      nonce     = "#{Random.new(Time.now.to_i).rand(100000000000000)}"
      timestamp = "#{Time.now.to_i}"
      signature = Digest::SHA1.hexdigest(@app_secret + nonce + timestamp)

      {
        'app-key' => @app_key,
        'nonce' => nonce,
        'timestamp' => timestamp,
        'signature' => signature
      }
    end

    def headers
      header = { 'content-type' => 'application/x-www-form-urlencoded',
                 'user-agent'   => @user_agent}
      header.merge!(make_signature)
    end

    def http_call url, headers, data
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')        # enable SSL/TLS
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # 这个也很重要

      req = Net::HTTP::Post.new(uri.path, initheader = headers)
      req.body = URI.encode_www_form(data)
      res = http.request(req)
      JSON.parse(res.body)
    end

    def post action, params = nil
      http_call(@api_host + action + "." + @response_type, headers, params)
    end

    def user_get_token user_id, name, portrait_uri
      post( ACTION_USER_TOKEN, { userId: user_id, name: name, portraitUri: portrait_uri } )
    end

    def add_blacklist user_id, black_user_id
      post( ACTION_USER_BLACKLIST_ADD, { userId: user_id, blackUserId: black_user_id } )
      post( ACTION_USER_BLACKLIST_ADD, { userId: black_user_id, blackUserId: user_id } )
    end

    def remove_blacklist user_id, black_user_id
      post( ACTION_USER_BLACKLIST_REMOVE, { userId: user_id, blackUserId: black_user_id } )
      post( ACTION_USER_BLACKLIST_REMOVE, { userId: black_user_id, blackUserId: user_id } )
    end

    def message_publish from_user_id, to_user_id, object_name, content, push_content, push_data
      post( ACTION_MESSAGE_PUBLISH,
            {
              fromUserId: from_user_id,
              toUserId: to_user_id,
              objectName: object_name,
              content: content,
              pushContent: push_content.to_s,
              pushData: push_data.to_s
            }
          )
    end

    def message_system_publish from_user_id, to_user_id, object_name, content, push_content, push_data
      post( ACTION_MESSAGE_SYSTEM_PUBLISH,
            {
              fromUserId: from_user_id,
              toUserId: to_user_id,
              objectName: object_name,
              content: content,
              pushContent: push_content.to_s,
              pushData: push_data.to_s
            }
          )
    end

    def message_group_publish from_user_id, to_group_id, object_name, content, push_content, push_data
      post( ACTION_MESSAGE_GROUP_PUBLISH,
            {
              fromUserId: from_user_id,
              toGroupId: to_group_id,
              objectName: object_name,
              content: content,
              pushContent: push_content.to_s,
              pushData: push_data.to_s
            }
          )
    end

    def message_chatroom_publish from_user_id, to_chatroom_id, object_name, content
      post( ACTION_MESSAGE_CHATROOM_PUBLISH,
            { fromUserId: from_user_id,
              toGroupId: to_chatroom_id,
              objectName: object_name,
              content: content
            }
          )
    end

    def message_broadcast from_user_id, object_name, content
      post( ACTION_MESSAGE_BROADCAST,
            {
              fromUserId: from_user_id,
              objectName: object_name,
              content: content
            }
          )
    end

    def group_sync user_id, groups
      groups.each { |k, v| group_mapping["group[#{k}]"] = v }
      group_mapping[:userId] = user_id

      post( ACTION_GROUP_SYNC, group_mapping)
    end

    def group_create user_id_list, group_id, group_name
      post( ACTION_GROUP_CREATE,
            {
              userId: user_id_list,
              groupId: group_id,
              groupName: group_name
            }
          )
    end

    def group_join user_id_list, group_id, group_name
      post( ACTION_GROUP_JOIN,
            {
              userId: user_id_list,
              groupId: group_id,
              groupName: group_name
            }
          )
    end

    def group_quit user_id_list, group_id
      post( ACTION_GROUP_QUIT,
            {
              userId: user_id_list,
              groupId: group_id
            }
          )
    end

    def group_dismiss user_id, group_id
      post( ACTION_GROUP_DISMISS,
            {
              userId: user_id,
              groupId: group_id,
            }
          )
    end

    def chatroom_create chatrooms
      chatrooms.each { |k, v| chatroom_mapping["charoom[#{k}]"] = v }
      post( ACTION_CHATROOM_CREATE, chatroom_mapping )
    end

    def chatroom_destroy chatroom_id_list=nil
      post( ACTION_CHATROOM_DESTROY, { chatroomId: chatroom_id_list.to_a } )
    end

    def chatroom_query chatroom_id_list=nil
      post( ACTION_CHATROOM_QUERY, { chatroomId: chatroom_id_list.to_a } )
    end
  end
end