require 'test/unit'
require 'rongyun'

class RongyunTest < Test::Unit::TestCase
  def test_make_signature
    client = Rongyun::Client.new "pvxdm17jx5eqr", "T6Kb5lVqeLz"
    result = client.make_signature
    assert true
  end

  def test_user_get_token
    client = Rongyun::Client.new "pvxdm17jx5eqr", "T6Kb5lVqeLz"
    result = client.user_get_token("1", "test", "http://test/1")
    assert_equal result["code"], 200
    result = client.user_get_token("U:8d4f905dae5c198d4cfe9f951cfdb0eb", "", "http://test/2")
    assert_equal result["code"], 200
  end

  def test_message_publish
    client = Rongyun::Client.new "pvxdm17jx5eqr", "T6Kb5lVqeLz"
    result = client.message_publish("2", "1", "RC:TxtMsg", "{'content':'hello','extra':'helloExtra'}")
    assert_equal result["code"], 200

    result = client.message_publish("2", ["1"], "RC:TxtMsg", "{'content':'hello','extra':'helloExtra'}")
    assert_equal result["code"], 200
  end

  def test_message_system_publish
    client = Rongyun::Client.new "pvxdm17jx5eqr", "T6Kb5lVqeLz"
    result = client.message_system_publish("2", "1", "RC:TxtMsg", "{'content':'hello','extra':'helloExtra'}")
    assert_equal result["code"], 200
    result = client.message_system_publish("2", ["1", "2"], "RC:TxtMsg", "{'content':'hello','extra':'helloExtra'}")
    assert_equal result["code"], 200
  end
end
