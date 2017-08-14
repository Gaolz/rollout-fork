# rollout

Fast feature flags based on Redis.

[<img src="https://travis-ci.org/FetLife/rollout.svg?branch=master" alt="Build
Status" />](https://travis-ci.org/FetLife/rollout)

## Install it

    gem install rollout

## How it works

Initialize a rollout object. I assign it to a global var.

```ruby
require 'redis'

$redis   = Redis.new
$rollout = Rollout.new($redis)
```

Check whether a feature is active for a particular user:

```ruby
$rollout.active?(:chat, User.first) # => true/false
```

Update data specific to a feature:

```ruby
$rollout.set_feature_data(:chat, description: 'foo', release_date: 'bar', whatever: 'baz')
```

Check whether a feature is active globally:

```ruby
$rollout.active?(:chat)
```

You can activate features using a number of different mechanisms.

## Groups

Rollout ships with one group by default: "all", which does exactly what it
sounds like.

You can activate the all group for the chat feature like this:

    $rollout.activate_group(:chat, :all)

You might also want to define your own groups. We have one for our caretakers:

    $rollout.define_group(:caretakers) do |user|
      user.caretaker?
    end

You can activate multiple groups per feature.

Deactivate groups like this:

    $rollout.deactivate_group(:chat, :all)

## Specific Users

You might want to let a specific user into a beta test or something. If that
user isn't part of an existing group, you can let them in specifically:

    $rollout.activate_user(:chat, @user)

Deactivate them like this:

    $rollout.deactivate_user(:chat, @user)

## User Percentages

If you're rolling out a new feature, you might want to test the waters by
slowly enabling it for a percentage of your users.

    $rollout.activate_percentage(:chat, 20)

The algorithm for determining which users get let in is this:

    CRC32(user.id) % 100_1000 < percentage * 1_000

So, for 20%, users 0, 1, 10, 11, 20, 21, etc would be allowed in. Those users
would remain in as the percentage increases.

Deactivate all percentages like this:

    $rollout.deactivate_percentage(:chat)

_Note that activating a feature for 100% of users will also make it active
"globally". That is when calling Rollout#active? without a user object._

In some cases you might want to have a feature activated for a random set of
users. It can come specially handy when using Rollout for split tests.

    $rollout = Rollout.new($redis, randomize_percentage: true)

When on `randomize_percentage` will make sure that 50% of users for feature A
are selected independently from users for feature B.

## Global actions

While groups can come in handy, the actual global setter for a feature does not require a group to be passed.

```ruby
$rollout.activate(:chat)
```

In that case you can check the global availability of a feature using the following

```ruby
$rollout.active?(:chat)
```

And if something is wrong you can set a feature off for everybody using

Deactivate everybody at once:

    $rollout.deactivate(:chat)

For many of our features, we keep track of error rates using redis, and
deactivate them automatically when a threshold is reached to prevent service
failures from cascading. See http://github.com/jamesgolick/degrade for the
failure detection code.

## Namespacing

Rollout separates its keys from other keys in the data store using the
"feature" keyspace.

If you're using redis, you can namespace keys further to support multiple
environments by using the
[redis-namespace](https://github.com/resque/redis-namespace) gem.

    $ns = Redis::Namespace.new(Rails.env, :redis => $redis)
    $rollout = Rollout.new($ns)
    $rollout.activate_group(:chat, :all)

This example would use the "development:feature:chat:groups" key.

## misc/check_rollout.rb

In our infrastructure, rollout obviously allows us to progressively enable new
features but we also use it to automatically disable features and services
that break or fail to prevent them from causing cascading failures and wiping
out our entire system.

When a feature reaches "maturity" - in other words, expected to be at 100%
rollout all the time - we use check_rollout.rb to setup nagios alerts on the
rollouts so that we get paged if one of them gets disabled.

## Implementations in other languages

*   Python: http://github.com/asenchi/proclaim
*   PHP: https://github.com/opensoft/rollout
*   Clojure: https://github.com/tcrayford/shoutout


## Contributors

*   James Golick - Creator - https://github.com/jamesgolick
*   Eric Rafaloff - Maintainer - https://github.com/EricR


## Copyright

Copyright (c) 2010-InfinityAndBeyond BitLove, Inc. See LICENSE for details.