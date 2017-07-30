class Rollout
    def initialize(redis)
        @redis = redis
        @groups = { "all" => lambda { |user| true} }
    end

    def activate_globally(feature)
        @redis.sadd(globaly_key(feature), feature)
    end

    def deactivate_globally(feature)
        @redis.srem(globaly_key(feature))
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

    def activate_percentage(feature, percentage)
        @redis.set(percentage_key(feature), percentage)
    end

    def deactivate_percentage(feature)
        @redis.del(percentage_key(feature))
    end

    def deactivate_all(feature)
        @redis.del(group_key(feature))
        @redis.del(user_key(feature))
        @redis.del(percentage_key(feature))
        deactivate_globally(feature)
    end

    def define_group(group, &block)
        @groups[group.to_s] = block
    end

    def active?(feature, user = nil)
        # @redis.smembers(group_key(feature)).any? { |group| @groups[group].call(user) }
        if user
            active_globally?(feature) ||
                user_in_active_group?(feature, user) ||
                    user_active?(feature, user) ||
                        user_within_active_percentage?(feature, user)
        else
            active_globally?(feature)
        end
    end

    def info(feature)
        {
            :percentage => (active_percentage(feature) || 0).to_i,
            :groups => active_groups(feature).map { |g| g.to_sym },
            :users => active_user_ids(feature)
        }
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

    private def percentage_key(name)
        "#{key(name)}:percentage"
    end

    private def globaly_key(name)
        "feature:__global__"
    end

    private def active_groups(feature)
        @redis.smembers(group_key(feature)) || []
    end

    private def active_user_ids(feature)
        @redis.smembers(user_key(feature)).map { |id| id.to_i }
    end

    private def active_percentage(feature)
        @redis.get(percentage_key(feature))
    end

    private def active_globally?(feature)
        @redis.sismember(global_key(feature), feature)
    end

    private def user_active?(feature, user)
        @redis.sismember(user_key(feature), user.id)
    end

    private def user_in_active_group?(feature, user)
        (@redis.smembers(group_key(feature)) || []).any? do |group|
            @groups.key?(group) && @group[group.to_s].call(user)
        end
    end

    private def user_within_active_percentage?(feature, user)
        percentage = active_percentage(feature)
        return false if percentage.nil?

        user.id % 100 < percentage.to_i
    end
end