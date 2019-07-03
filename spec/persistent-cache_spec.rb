require 'spec_helper'

describe Persistent::Cache do
  before :each do
    @db_name = get_database_name
    @mock_storage = double(Persistent::StorageSQLite)
    @test_key = "testkey"
    @test_value = "testvalue"
    FileUtils.rm_f(@db_name)
  end

  context "when constructing" do
    it "should receive database connection details and create a StorageSQLite instance if specified" do
      @pcache = Persistent::Cache.new(@db_name, Persistent::Cache::STORAGE_SQLITE)
      expect(@pcache.class).to eq(Persistent::Cache)
      expect(@pcache.storage.is_a?(Persistent::StorageSQLite)).to eq(true)
    end

    it "should raise an ArgumentError if storage details have not been provided" do
      expect {
        Persistent::Cache.new(nil)
      }.to raise_error(ArgumentError)
    end

    it "should remember the freshness interval if provided" do
      @pcache = Persistent::Cache.new(@db_name, 123)
      expect(@pcache.fresh).to eq(123)
    end

    it "should remember the storage details provided" do
      @pcache = Persistent::Cache.new(@db_name, 123)
      expect(@pcache.storage_details).to eq(@db_name)
    end

    it "should default the freshness interval to FRESH if not provided" do
      @pcache = Persistent::Cache.new(@db_name)
      expect(@pcache.fresh).to eq(Persistent::Cache::FRESH)
    end

    it "should raise an ArgumentError if an unknown storage type has been provided" do
      expect {
        Persistent::Cache.new(@db_name, 100, "unknown")
      }.to raise_error(ArgumentError)
    end
  end

  context "When assigning a value to a key" do
    it "should ask the storage handler to first delete, then save the key/value pair" do
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)
      expect(@mock_storage).to receive(:delete_entry)
      expect(@mock_storage).to receive(:save_key_value_pair).with(@test_key, @test_value, nil)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache[@test_key] = @test_value
    end

    it "should ask the storage handler to delete if the value is nil using []" do
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)
      expect(@mock_storage).to receive(:delete_entry).with(@test_key)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache[@test_key] = nil
    end

    it "should ask the storage handler to delete if the value is nil using set()" do
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)
      expect(@mock_storage).to receive(:delete_entry).with(@test_key)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache.set(@test_key, nil, Time.now)
    end

    it "should serialize the key and value for persistence" do
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)
      expect(@mock_storage).to receive(:delete_entry)
      expect(@mock_storage).to receive(:save_key_value_pair).with(@test_key, @test_value, nil)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache[@test_key] = @test_value
    end

    it "should ask the storage handler to store the value, with a specific timestamp if specified" do
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)
      expect(@mock_storage).to receive(:delete_entry)
      timestamp = Time.now - 100
      expect(@mock_storage).to receive(:save_key_value_pair).with(@test_key, @test_value, timestamp)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache.set(@test_key, @test_value, timestamp)
    end
  end
  
  context "When looking up a value given its key" do
    it "should retrieve the value from storage using lookup_key and deserialize the value" do
      expect(@mock_storage).to receive(:delete_entry)
      expect(@mock_storage).to receive(:save_key_value_pair).with(@test_key, @test_value, nil)
      expect(@mock_storage).to receive(:lookup_key).with(@test_key).and_return([@test_value, Time.now.to_s])
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache[@test_key] = @test_value
      result = @pcache[@test_key]
      expect(result).to eq(@test_value)
    end

    it "should return nil if a value exists but it not fresh" do
      expect(@mock_storage).to receive(:delete_entry)
      expect(@mock_storage).to receive(:lookup_key).with(@test_key).and_return([@test_value, (Time.now - Persistent::Cache::FRESH).to_s])
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)

      @pcache = Persistent::Cache.new(@db_name)
      expect(@pcache[@test_key].nil?).to eq(true)
    end

    it "should remove from the cache an entry it encounters that is not fresh" do
      expect(@mock_storage).to receive(:delete_entry)
      expect(@mock_storage).to receive(:lookup_key).with(@test_key).and_return([@test_value, (Time.now - Persistent::Cache::FRESH).to_s])
      expect(Persistent::StorageSQLite).to receive(:new).and_return(@mock_storage)

      @pcache = Persistent::Cache.new(@db_name)
      @pcache[@test_key]
    end

    it "should return nil if a key is not in the database" do
      @pcache = Persistent::Cache.new(@db_name)
      result = @pcache["thiskeydoesnotexist"]
      expect(result.nil?).to eq(true)
    end

    it "should serialize the key for lookup" do
      @pcache = Persistent::Cache.new(@db_name)
      @pcache["testkey"] = "testvalue"
      expect(@pcache).to receive(:lookup_key).with("testkey")
      @pcache["testkey"]
    end
  end

  context "it should behave like a cache" do
    it "should return the correct size" do
      setup_cache
      expect(@pcache.size).to eq(3)
    end

    it "should return the list of keys when asked" do
      setup_cache
      expect(@pcache.keys.size).to eq(3)
      expect(@pcache.keys.include?("one")).to eq(true)
      expect(@pcache.keys.include?("two")).to eq(true)
      expect(@pcache.keys.include?("three")).to eq(true)
    end

    it "should allow iteration through each" do
      setup_cache
      test = []
      @pcache.each do |key, value|
        test << "#{key} => #{value}"
      end
      expect(test.size).to eq(3)
      expect(test.include?("one => value one")).to eq(true)
      expect(test.include?("two => value two")).to eq(true)
      expect(test.include?("three => value three")).to eq(true)
    end

    it "should delete all entries in the database when asked to clear" do
      setup_cache
      @pcache.clear
      expect(@pcache.size).to eq(0)
    end

    it "should be able to handle multiple accesses to the same db" do
      pcache = Persistent::Cache.new("multidb") 
      pcache["multi_test"] = 0

      threads = []
      100.times do
        threads << Thread.new do
          Thread.current['pcache'] = Persistent::Cache.new("multidb")
          if (!Thread.current['pcache'].nil? && !Thread.current['pcache']["multi_test"].nil?)
            Thread.current['pcache']["multi_test"] += 1
          end
        end
      end
      threads.each { |t| t.join }

      p pcache["multi_test"]
      
    end

    def setup_cache
      FileUtils.rm_f(@db_name)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache["one"] = "value one"
      @pcache["two"] = "value two"
      @pcache["three"] = "value three"
    end
  end

  context "when encoding is a requirement" do
    it "should not retrieve values for keys in a different encoding from that it was stored with" do
      setup_cache
      expect(@pcache[@encoded_key]).to eq("some value")
      expect(@pcache["encoded"].nil?).to eq(true)
    end

    it "should retrieve values for keys stored in an encoding explicitly specified" do
      setup_cache(Encoding::ISO_8859_1)
      expect(@pcache[@encoded_key]).to eq("some value")
      expect(@pcache["encoded"]).to eq("some value")
    end

    def setup_cache(encoding = nil)
      FileUtils.rm_f(@db_name)
      @pcache = Persistent::Cache.new(@db_name)
      @pcache.encoding = encoding if encoding
      @encoded_key = "encoded".encode!(Encoding::ISO_8859_1)
      @pcache[@encoded_key] = "some value"
    end
  end

  context "when needing to know if a key is in the cache" do
    it "should return nil if the key is not present" do
      setup_cache
      expect(@pcache.key?(1)).to eql(nil)
    end

    it "should return the key if the key is present" do
      setup_cache
      @pcache[1] = "1"
      expect(@pcache.key?(1)).to eql(1)
    end

    it "should return the key even if the entry is stale" do
      setup_cache
      @pcache[1] = "1"
      sleep 2
      expect(@pcache.key?(1)).to eql(1)
      expect(@pcache[1]).to eql(nil)
    end

    def setup_cache(encoding = nil)
      FileUtils.rm_f(@db_name)
      @pcache = Persistent::Cache.new(@db_name, 1)
      @pcache.encoding = encoding if encoding
    end
  end
end
