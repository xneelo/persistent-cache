require 'spec_helper'

describe Persistent::StorageRAM do
  before :each do
    @test_key = "testkey"
    @test_value = "testvalue"
    @iut = Persistent::StorageRAM.new
  end

  context "when constructed" do
    it "should have a storage hash in RAM" do
      expect(@iut.storage.nil?).to eql(false)
      expect(@iut.storage.instance_of?(Hash)).to eql(true)
    end
  end

  context "when asked to store a key value pair" do
    it "should store the key/value pair in RAM, with the current time as timestamp" do
      start_time = Time.now - 1
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump(@test_value))
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result[0]).to eql(Marshal.dump(@test_value))
      test_time = Time.parse(result[1])
      expect(test_time).to be > start_time
      expect(test_time).to be < start_time + 600
    end

    it "should store the key/value pair in RAM, with a timestamp specified" do
      test_time = (Time.now - 2500)
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump(@test_value), test_time)
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result.nil?).to eql(false)
      expect(result[0]).to eql(Marshal.dump(@test_value))
      time_retrieved = Time.parse(result[1])
      expect(time_retrieved.to_s).to eql(test_time.to_s)
    end

    it "should overwrite the existing key/value pair if they already exist" do
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump(@test_value))
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump("testvalue2"))
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result[0]).to eql(Marshal.dump("testvalue2"))
    end
  end

  context "When looking up a value given its key" do
    it "should retrieve the value from RAM" do
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump(@test_value))
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result[0]).to eql(Marshal.dump(@test_value))
    end

    it "should retrieve the timestamp when the value was stored from RAM" do
      now = Time.now.to_s
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump(@test_value))
      sleep 1
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result[1]).to eql(now)
    end

    it "should return an empty array if a key is not in RAM" do
      @iut.delete_entry(Marshal.dump(@test_key))
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result).to eql([])
      expect(result[0]).to eql(nil)
    end
  end

  context "when asked to delete an entry" do
    it "should not raise an error if the entry is not present" do
      @iut.delete_entry(Marshal.dump("shouldnotbepresent"))
    end

    it "should delete the entry if it is present" do
      @iut.save_key_value_pair(Marshal.dump(@test_key), Marshal.dump(@test_value))
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result[0]).to eql(Marshal.dump(@test_value))
      @iut.delete_entry(Marshal.dump(@test_key))
      result = @iut.lookup_key(Marshal.dump(@test_key))
      expect(result).to eql([])
    end
  end

  context "when asked the size of the RAM database" do
    it "should return 0 if the RAM database has no entries" do
      expect(@iut.size).to eql(0)
    end

    it "should return the number of entries" do
      populate_database(@iut)
      expect(@iut.size).to eql(3)
    end
  end

  context "when asked for the keys in the RAM database" do
    it "should return an empty array if there are no entries in the RAM database" do
      expect(@iut.keys).to eql([])
    end

    it "should return the keys in the RAM database" do
      populate_database(@iut)
      keys = @iut.keys.flatten
      expect(keys.include?(Marshal.dump("one"))).to eql(true)
      expect(keys.include?(Marshal.dump("two"))).to eql(true)
      expect(keys.include?(Marshal.dump("three"))).to eql(true)
      expect(@iut.size).to eql(3)
    end

    it "should return the keys in an array, with each key in its own sub-array" do
      populate_database(@iut)
      found = false
      test = Marshal.dump("one")
      found = true if (@iut.keys[0][0] == test or @iut.keys[0][1] == test or @iut.keys[0][2] == test)
      expect(found).to eql(true)
    end
  end

  context "when asked to clear the RAM database" do
    it "should delete all entries in RAM" do
      populate_database(@iut)
      @iut.clear
      expect(@iut.size).to eql(0)
    end
  end

  def populate_database(iut)
    iut.save_key_value_pair(Marshal.dump("one"), Marshal.dump("one"))
    iut.save_key_value_pair(Marshal.dump("two"), Marshal.dump("two"))
    iut.save_key_value_pair(Marshal.dump("three"), Marshal.dump("three"))
  end
end
