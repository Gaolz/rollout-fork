require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Rollout" do
    before do
        @redis = Redis.new
        @rollout = Rollout.new(@redis)
    end

    describe "when a group is activated" do
        before do
            @rollout.define_group(:fivesonly) { |user| user.id == 5 }
            @rollout.activate_group(:chat, :fivesonly)
        end

        it "the feature is active for users for which the block evaluates to true" do
            @rollout.should be_active(:chat, stub(:id => 5))
        end

        it "is not active for users for which the block evaluates to false" do
            @rollout.should_not be_active(:chat, stub(:id => 1))
        end

        it "is not active if a group is found in Redis but not defined in Rollout" do
            @rollout.activate_group(:chat, :fake)
            @rollout.should_not be_active(:chat, stub(:id => 1))
        end
    end

    describe "the default all group" do
        before do
            @rollout.activate_group(:chat, :all)
        end

        it "evaluates to true no matter what" do
            @rollout.should be_active(:chat, stub(:id => 0))
        end
    end

    describe "deactivating a group" do
        before do
            @rollout.define_group(:fivesonly) { |user| user.id == 5 }
            @rollout.activate_group(:chat, :all)
            @rollout.activate_group(:chat, :fivesonly)
            @rollout.deactivate_group(:chat, :all)
        end

        it "deactivates the rules for that group" do
            @rollout.should_not be_active(:chat, stub(:id => 10))
        end

        it "leaves the other groups active" do
            @rollout.should be_active(:chat, stub(:id => 5))
        end
    end

    describe "deactivating a feature completely" do
        before do
            @rollout.define_group(:fivesonly) { |user| user.id == 5 }
            @rollout.activate_group(:chat, :all)
            @rollout.activate_group(:chat, :fivesonly)
            @rollout.activate_user(:chat, stub(:id => 51))
            @rollout.activate_percentage(:chat, 100)
            @rollout.activate_globally(:chat)
            @rollout.deactivate_all(:chat)
        end

        it "removes all of the groups" do
            @rollout.should_not be_active(:chat, stub(:id => 0))
        end

        it "removes all of the users" do
            @rollout.should_not be_active(:chat, stub(:id => 51))
        end

        it "removes the percentage" do
            @rollout.should_not be_active(:chat, stub(:id => 24))
        end

        it "removes globally" do
            @rollout.should_not be_active(:chat)
        end
    end

    describe "activating a specific user" do
        before do
            @rollout.activate_user(:chat, stub(:id => 42))
        end

        it "is active for that user" do
            @rollout.should be_active(:chat, stub(:id => 42))
        end

        it "remains inactive for other users" do
            @rollout.should_not be_active(:chat, stub(:id => 24))
        end
    end

    describe "deactivating a specific user" do
        before do
            @rollout.activate_user(:chat, stub(:id => 42))
            @rollout.activate_user(:chat, stub(:id => 24))
            @rollout.deactivate_user(:chat, stub(:id => 42))
        end

        it "that user should no longer be active" do
            @rollout.should_not be_active(:chat, stub(:id => 42))
        end

        it "remains active for other active users" do
            @rollout.should be_active(:chat, stub(:id => 24))
        end
    end

    describe "activating a feature globally" do
        before do
            @rollout.activate_globally(:chat)
        end

        it "activates the feature" do
            @rollout.should be_active(:chat)
        end
    end

    describe "activating a feature for a percentage of users" do
        before do
            @rollout.activate_percentage(:chat, 20)
        end

        it "activating a feature for a percentage of users" do
            (1..120).select { |id| @rollout.active?(:chat, stub(:id => id)) }.length.should == 39
        end
    end

    describe "activating a feature for a percentage of users" do
        before do
            @rollout.activate_percentage(:chat, 20)
        end

        it "activates the feature for that percentage of the users" do
            (1..200).select { |id| @rollout.active?(:chat, stub(:id => id)) }.length.should == 40
        end
    end

    describe "activating a feature for a percentage of users" do
        before do
            @rollout.activate_percentage(:chat, 5)
        end

        it "activates the feature for that percentage of the users" do
            (1..100).select { |id| @rollout.active?(:chat, stub(:id => id)) }.length.should == 5
        end
    end

    describe "deactivating the percentage of users" do
        before do
            @rollout.activate_percentage(:chat, 100)
            @rollout.deactivate_percentage(:chat)
        end

        it "becomes inactive for all users" do
            @rollout.should_not be_active(:chat, stub(:id => 24))
        end
    end

    describe "deactivating the feature globally" do
        before do
            @rollout.activate_globally(:chat)
            @rollout.deactivate_globally(:chat)
        end
        
        it "becomes inactive" do
            @rollout.should_not be_active(:chat)
        end
    end

    describe "#get" do
        before do
            @rollout.activate_percentage(:chat, 10)
            @rollout.activate_group(:chat, :caretakers)
            @rollout.activate_group(:chat, :greeters)
            @rollout.activate_globally(:signup)
            @rollout.activate_user(:chat, stub(:id => 42))
        end

        it "returns the feature object" do
            feature = @rollout.get(:chat)
            feature.groups.should == [:caretakers, :greeters]
            feature.percentage.should == 10
            feature.users.should == [42]

            feature = @rollout.get(:signup)
            feature.groups.should be_empty
            feature.users.should be_empty
            feature.percentage.should == 100
        end
    end
end