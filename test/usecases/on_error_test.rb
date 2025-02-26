require_relative '../test_helper'

class OnErrorTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :created_at, :updated_at

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
      @created_at = Time.now
      @updated_at = Time.now
    end

    # rubocop:disable Style/RedundantException
    def email
      raise RuntimeError, 'Error!'
    end
    # rubocop:enable Style/RedundantException
  end

  class UserResource
    include Alba::Resource

    key :user

    attributes :id, :name, :email
  end

  class UserResource1 < UserResource
    on_error :raise
  end

  class UserResource2 < UserResource
    on_error :ignore
  end

  class UserResource3 < UserResource
    on_error :nullify
  end

  class UserResource4 < UserResource
    on_error do |error, _, key|
      [key, error.message]
    end
  end

  class UserResource5 < UserResource
    Alba.on_error do |error|
      ['error', error.message]
    end
    on_error :ignore
  end

  def setup
    Alba.on_error :raise
    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  def test_on_error_default
    assert_raises RuntimeError do
      UserResource.new(@user).serialize
    end
  end

  def test_on_error_raise
    assert_raises RuntimeError do
      UserResource1.new(@user).serialize
    end
  end

  def test_on_error_ignore
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA"}}',
      UserResource2.new(@user).serialize
    )
  end

  def test_on_error_nullify
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","email":null}}',
      UserResource3.new(@user).serialize
    )
  end

  def test_on_error_block
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","email":"Error!"}}',
      UserResource4.new(@user).serialize
    )
  end

  def test_on_error_resource_local_wins_against_global
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA"}}',
      UserResource5.new(@user).serialize
    )
  end
end
