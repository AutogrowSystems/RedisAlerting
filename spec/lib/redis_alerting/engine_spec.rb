require 'spec_helper'

describe RedisAlerting::Engine do
  subject(:engine) { RedisAlerting::Engine.new(config, redis) }
  let(:config)     { test_config }
  let(:redis)      { ::Redis.new }
  
  before(:all) do
    @r = Redis.new
    @key = "ph"
    @source = test_config[:sources][:ph]
    @namespace = test_config[:namespace]
  end

  before(:each) do
    @r.set "#{@namespace}.ph.min", 4000
    @r.set "#{@namespace}.ph.max", 9000
  end

  after(:each) { @r.del @namespace }
  
  context "the reading is above the max limit" do
    before(:each) { @r.set @source, 9100 }

    it "should add the key to the set" do
      engine.run
      expect(redis.sismember(config[:namespace], "ph")).to be_truthy
    end

    it "should add the number of members in the set" do
      expect {
        engine.run
      }.to change { redis.scard config[:namespace] }.by(1)
    end
  end

  context "the reading is below the max limit" do
    before(:each) { @r.set @source, 3900 }

    it "should add the number of members in the set" do
      expect {
        engine.run
      }.to change { redis.scard config[:namespace] }.by(1)
    end

    it "should add the key to the set" do
      engine.run
      expect(redis.sismember(config[:namespace], "ph")).to be_truthy
    end
  end

  context "an alert exists" do
    before(:each) { @r.sadd @namespace, "ph" }

    context "and the reading comes back into range" do
      before(:each) { @r.set @source, 6800 }

      it "should remove the key from the set" do
        engine.run
        expect(redis.sismember(config[:namespace], "ph")).to be_falsey
      end
    end
  end

end