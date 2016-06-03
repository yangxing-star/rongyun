require 'rongyun/version'

require 'digest/sha1'
require 'net/https'
require 'uri'
require 'json'

module Rongyun
  class Client

    ACTION_USER_TOKEN = '/user/getToken'
    ACTION_USER_REFRESH = '/user/refresh'
    ACTION_USER_BLOCK = '/user/block'
    ACTION_USER_UNBLOCK = '/user/unblock'
    ACTION_USER_BLOCK_QUERY = '/user/block/query'
    ACTION_USER_CHECKONLINE = '/user/checkOnline'
    ACTION_USER_BLACKLIST_ADD = '/user/blacklist/add'
    ACTION_USER_BLACKLIST_REMOVE = '/user/blacklist/remove'
    ACTION_USER_TAG_SET = '/user/tag/set'

    ACTION_MESSAGE_PUBLISH = '/message/private/publish'
    ACTION_MESSAGE_SYSTEM_PUBLISH = '/message/system/publish'
    ACTION_MESSAGE_GROUP_PUBLISH = '/message/group/publish'
    ACTION_MESSAGE_CHATROOM_PUBLISH = '/message/chatroom/publish'
    ACTION_MESSAGE_BROADCAST = '/message/broadcast'
    ACTION_MESSAGE_HISTORY = '/message/history'
    ACTION_MESSAGE_HISTORY_DELETE = '/message/history/delete'

    ACTION_GROUP_SYNC = '/group/sync'
    ACTION_GROUP_CREATE = '/group/create'
    ACTION_GROUP_JOIN = '/group/join'
    ACTION_GROUP_QUIT = '/group/quit'
    ACTION_GROUP_DISMISS = '/group/dismiss'
    ACTION_GROUP_REFRESH = '/group/refresh'
    ACTION_GROUP_USER_QUERY = '/group/user/query'
    ACTION_GROUP_USER_GAG_ADD = '/group/user/gag/add'
    ACTION_GROUP_USER_GAG_ROLLBACK = '/group/user/gag/rollback'
    ACTION_GROUP_USER_GAG_LIST = '/group/user/gag/list'

    ACTION_WORDFILTER_ADD = '/wordfilter/add'
    ACTION_WORDFILTER_DELETE = '/wordfilter/delete'
    ACTION_WORDFILTER_LIST = '/wordfilter/list'

    ACTION_CHATROOM_CREATE = '/chatroom/create'
    ACTION_CHATROOM_DESTROY = '/chatroom/destroy'
    ACTION_CHATROOM_QUERY = '/chatroom/query'

    ACTION_PUSH = '/push'

    def initialize(app_key = nil, app_secret = nil, verify = true)
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

    def headers(content_type='application/x-www-form-urlencoded')
      header = { 'content-type' => content_type,
                 'user-agent'   => @user_agent}
      header.merge!(make_signature)
    end

    def http_call(url, headers, data)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')        # enable SSL/TLS
      http.ssl_version = :TLSv1
      # http.ciphers = ['RC4-SHA']
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # 这个也很重要

      req = Net::HTTP::Post.new(uri.path, initheader = headers)
      req.body = body(headers['content-type'], data)
      res = http.request(req)
      response_object(JSON.parse(res.body))
    end

    def response_object(body)
      response = Struct.new(:success, :data).new
      response.success = body['code'] == 200
      response.data = body
      response
    end

    def body(content_type, data)
      content_type == 'application/x-www-form-urlencoded' ? URI.encode_www_form(data) : data.to_json
    end

    def post(action, params = nil)
      http_call(@api_host + action + "." + @response_type, headers, params)
    end

    def post_json(action, params = nil)
      http_call(@api_host + action + "." + @response_type, headers('application/json'), params)
    end

    def user_get_token(user_id, name, portrait_uri)
      post( ACTION_USER_TOKEN, { userId: user_id, name: name, portraitUri: portrait_uri } )
    end

    def user_refresh(user_id, name, portrait_uri)
      post( ACTION_USER_REFRESH, { userId: user_id, name: name, portraitUri: portrait_uri } )
    end

    def user_check_online(user_id)
      post( ACTION_USER_CHECKONLINE, { userId: user_id } )
    end

    def add_blacklist(user_id, black_user_id)
      post( ACTION_USER_BLACKLIST_ADD, { userId: user_id, blackUserId: black_user_id } )
      post( ACTION_USER_BLACKLIST_ADD, { userId: black_user_id, blackUserId: user_id } )
    end

    def remove_blacklist(user_id, black_user_id)
      post( ACTION_USER_BLACKLIST_REMOVE, { userId: user_id, blackUserId: black_user_id } )
      post( ACTION_USER_BLACKLIST_REMOVE, { userId: black_user_id, blackUserId: user_id } )
    end

    def user_block(user_id, minute = 10)
      post( ACTION_USER_BLOCK, { userId: user_id } )
    end

    def user_unblock(user_id)
      post( ACTION_USER_UNBLOCK, { userId: user_id } )
    end

    def user_block_query
      post( ACTION_USER_BLOCK_QUERY )
    end

    def user_tag_set(user_id, tags)
      post_json( ACTION_USER_TAG_SET, { userId: user_id, tags: tags } )
    end

    def add_wordfilter(word)
      post( ACTION_WORDFILTER_ADD, { word: word } )
    end

    def delete_wordfilter(word)
      post( ACTION_WORDFILTER_DELETE, { word: word } )
    end

    def wordfilter_list(word)
      post( ACTION_WORDFILTER_LIST )
    end

    def message_publish(from_user_id, to_user_id, object_name, content, push_content, push_data)
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

    def message_system_publish(from_user_id, to_user_id, object_name, content, push_content, push_data)
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

    def message_group_publish(from_user_id, to_group_id, object_name, content, push_content, push_data)
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

    def message_chatroom_publish(from_user_id, to_chatroom_id, object_name, content)
      post( ACTION_MESSAGE_CHATROOM_PUBLISH,
            { fromUserId: from_user_id,
              toGroupId: to_chatroom_id,
              objectName: object_name,
              content: content
            }
          )
    end

    def message_broadcast(from_user_id, object_name, content, push_content, push_data, os)
      post( ACTION_MESSAGE_BROADCAST,
            {
              fromUserId: from_user_id,
              objectName: object_name,
              content: content,
              pushContent: push_content,
              pushData: push_data,
              os: os
            }
          )
    end

    def message_history_delete(date)
      post( ACTION_MESSAGE_HISTORY_DELETE, { date: date } )
    end

    def message_history(date)
      post( ACTION_MESSAGE_HISTORY, { date: date } )
    end

    def group_sync(user_id, groups)
      groups.each { |k, v| group_mapping["group[#{k}]"] = v }
      group_mapping[:userId] = user_id

      post( ACTION_GROUP_SYNC, group_mapping )
    end

    def group_create(user_ids, group_id, group_name)
      post( ACTION_GROUP_CREATE,
            {
              userId: user_ids,
              groupId: group_id,
              groupName: group_name
            }
          )
    end

    def group_join(user_ids, group_id, group_name)
      post( ACTION_GROUP_JOIN,
            {
              userId: user_ids,
              groupId: group_id,
              groupName: group_name
            }
          )
    end

    def group_quit(user_ids, group_id)
      post( ACTION_GROUP_QUIT, { userId: user_ids, groupId: group_id } )
    end

    def group_dismiss(user_id, group_id)
      post( ACTION_GROUP_DISMISS, { userId: user_id, groupId: group_id } )
    end

    def group_refresh(group_id, group_name)
      post( ACTION_GROUP_REFRESH, { groupId: group_id, groupName: group_name } )
    end

    def group_user_query(group_id)
      post( ACTION_GROUP_USER_QUERY, { groupId: group_id } )
    end

    def chatroom_create(chatrooms)
      chatrooms.each { |k, v| chatroom_mapping["charoom[#{k}]"] = v }
      post( ACTION_CHATROOM_CREATE, chatroom_mapping )
    end

    def chatroom_destroy(chatroom_id_list = nil)
      post( ACTION_CHATROOM_DESTROY, { chatroomId: chatroom_id_list.to_a } )
    end

    def chatroom_query(chatroom_id_list = nil)
      post( ACTION_CHATROOM_QUERY, { chatroomId: chatroom_id_list.to_a } )
    end

    def group_user_gag_add(user_ids, group_id, minute = 120)
      post( ACTION_GROUP_USER_GAG_ADD, { userId: user_ids, groupId: group_id, minute: minute.to_i } )
    end

    def group_user_gag_rollback(user_ids, group_id)
      post( ACTION_GROUP_USER_GAG_ROLLBACK, { userId: user_ids, groupId: group_id } )
    end

    def group_user_gag_list(group_id)
      post( ACTION_GROUP_USER_GAG_LIST, { groupId: group_id } )
    end

    def push(platform, audience, notification)
      post_json( ACTION_PUSH, { platform: platform, audience: audience, notification: notification } )
    end
  end
end
