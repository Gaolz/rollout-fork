class Rollout
    def initialize(redis)
        @redis = redis
        @groups = { "all" => lambda { |user| true} }
    end

    def activate_group(feature, group)
        @redis.sadd(group_key(feature), group)
    end

    def deactivate_group(feature, group)
        @redis.srem(group_key(feature), group)
    end

    def activate_user(feature, user)
        @redis.sadd(user_key(feature), user.id)
    end

    def deactivate_user(feature, user)
        @redis.srem(user_key(feature), user.id)
    end

    def deactivate_all(feature)
        @redis.del(group_key(feature))
        @redis.del(user_key(feature))
    end

    def define_group(group, &block)
        @groups[group.to_s] = block
    end

    def active?(feature, user)
        # @redis.smembers(group_key(feature)).any? { |group| @groups[group].call(user) }
        user_in_active_group?(feature, user) || user_active?(feature, user)
    end

    private def key(name)
        "feature:#{name}"
    end

    private def group_key(name)
        "#{key(name)}:groups"
    end

    private def user_key(name)
        "#{key(name)}:users"
    end

    private def user_in_active_group?(feature, user)
        @redis.sismember(user_key(feature), user.id)
    end

    private def user_in_active_group?(feature, user)
        @redis.smembers(group_key(feature)).any? { |group| @group[group.to_s].call(user) }
    end
end