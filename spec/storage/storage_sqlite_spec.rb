require 'spec_helper'

describe Persistent::StorageSQLite do
  before :each do
    @db_name = get_database_name
    delete_database
    @test_key = "testkey"
    @test_value = "testvalue"
    @iut = Persistent::StorageSQLite.new(@db_name)
 end

  def serialize(data)
    Base64.encode64(Marshal.dump(data))
  end

  def deserialize(data)
    Marshal.load(Base64.decode64(data))
  end

  context "when constructed" do
    it "should create the database if it does not exist" do
      expect(File.exists?(@db_name)).to eq(true)
    end

    it "should create a key_value table with key (TEXT) and value (TEXT) and timestamp (TEXT) columns" do
      handle = SQLite3::Database.open(@db_name)
      result = handle.execute "PRAGMA table_info(#{Persistent::StorageSQLite::DB_TABLE})"
      expect(result[0][1]).to eq("key")
      expect(result[0][2]).to eq("TEXT")
      expect(result[1][1]).to eq("value")
      expect(result[1][2]).to eq("TEXT")
      expect(result[2][1]).to eq("timestamp")
      expect(result[2][2]).to eq("TEXT")
    end


    it "should use the existing database if it does exist" do
      delete_database
      handle = SQLite3::Database.new(@db_name)
      handle.execute "create table test123 ( id int );"
      handle.close
      Persistent::StorageSQLite.new(@db_name)
      handle = SQLite3::Database.open(@db_name)
      result = handle.execute "select name from sqlite_master where type='table'"
      expect(result[0][0]).to eq("test123")
    end

    it "should have a database handler" do
      expect(@iut.storage_handler.is_a?(SQLite3::Database)).to eq(true)
    end

    it "should set the SQLite busy timeout to DB_TIMEOUT" do
      delete_database
      mock_database = double(SQLite3::Database)
      expect(mock_database).to receive(:execute)
      expect(mock_database).to receive(:busy_timeout=).with(Persistent::StorageSQLite::DB_TIMEOUT)
      expect(SQLite3::Database).to receive(:new).and_return(mock_database)
      Persistent::StorageSQLite.new(@db_name)
    end

    it "should raise an ArgumentError if storage details have not been provided" do
      expect {
        Persistent::StorageSQLite.new(nil)
      }.to raise_error(ArgumentError)
    end
  end

  context "when asked to store a key value pair" do
    it "should store the key/value pair in the db, with the current time as timestamp" do
      start_time = Time.now - 1
      @iut.save_key_value_pair(@test_key, @test_value)
      handle = SQLite3::Database.open(@db_name)
      result = handle.execute "select value, timestamp from #{Persistent::StorageSQLite::DB_TABLE} where key=?", serialize(@test_key)
      expect(result.nil?).to eq(false)
      expect(result[0].nil?).to eq(false)
      expect(result[0][0]).to eq(serialize(@test_value))
      test_time = Time.parse(result[0][1])
      expect(test_time).to be > start_time
      expect(test_time).to be < start_time + 600
    end

    it "should store the key/value pair in the db, with a timestamp specified" do
      test_time = (Time.now - 2500)
      @iut.save_key_value_pair(@test_key, @test_value, test_time)
      handle = SQLite3::Database.open(@db_name)
      result = handle.execute "select value, timestamp from #{Persistent::StorageSQLite::DB_TABLE} where key=?", serialize(@test_key)
      expect(result.nil?).to eq(false)
      expect(result[0].nil?).to eq(false)
      expect(result[0][0]).to eq(serialize(@test_value))
      time_retrieved = Time.parse(result[0][1])
      expect(time_retrieved.to_s).to eq(test_time.to_s)
    end

    it "should overwrite the existing key/value pair if they already exist" do
      @iut.save_key_value_pair(@test_key, @test_value)
      @iut.save_key_value_pair(@test_key, "testvalue2")
      handle = SQLite3::Database.open(@db_name)
      result = handle.execute "select value from #{Persistent::StorageSQLite::DB_TABLE} where key=?", serialize(@test_key)
      expect(result.nil?).to eq(false)
      expect(result[0].nil?).to eq(false)
      expect(result.size).to eq(1)
      expect(result[0][0]).to eq(serialize("testvalue2"))
    end
  end

  context "When looking up a value given its key" do
    it "should retrieve the value from the database" do
      @iut.save_key_value_pair(@test_key, @test_value)
      result = @iut.lookup_key(@test_key)
      expect(result[0]).to eq(@test_value)
    end

    it "should retrieve the timestamp when the value was stored from the database" do
      now = Time.now.to_s
      @iut.save_key_value_pair(@test_key, @test_value)
      sleep 1
      result = @iut.lookup_key(@test_key)
      expect(result[1]).to eq(now)
    end

    it "should return an empty array if a key is not in the database" do
      @iut.delete_entry(@test_key)
      result = @iut.lookup_key(@test_key)
      expect(result).to eq(nil)
    end
  end

  context "when asked to delete an entry" do
    it "should not raise an error if the entry is not present" do
      @iut.delete_entry(serialize("shouldnotbepresent"))
    end

    it "should delete the entry if it is present" do
      @iut.save_key_value_pair(@test_key, @test_value)
      result = @iut.lookup_key(@test_key)
      expect(result[0]).to eq(@test_value)
      @iut.delete_entry(@test_key)
      result = @iut.lookup_key(@test_key)
      expect(result).to eq(nil)
    end
  end

  context "when asked the size of the database" do
    it "should return 0 if the database has no entries" do
      expect(@iut.size).to eq(0)
    end

    it "should return the number of entries" do
      populate_database(@iut)
      expect(@iut.size).to eq(3)
    end
  end

  context "when asked for the keys in the database" do
    it "should return an empty array if there are no entries in the database" do
      expect(@iut.keys).to eq([])
    end

    it "should return the keys in the database" do
      populate_database(@iut)
      keys = @iut.keys.flatten
      expect(keys.include?("one")).to eq(true)
      expect(keys.include?("two")).to eq(true)
      expect(keys.include?("three")).to eq(true)
      expect(@iut.size).to eq(3)
    end

    it "should return the keys in an array" do
      populate_database(@iut)
      found = false
      test = "one"
      found = true if (@iut.keys.include?(test))
      expect(found).to eq(true)
    end
  end

  context "when asked to clear the database" do
    it "should not delete the database file" do
      populate_database(@iut)
      @iut.clear
      expect(File.exists?(@db_name)).to eq(true)
    end

    it "should delete all entries in the database" do
      populate_database(@iut)
      @iut.clear
      expect(@iut.size).to eq(0)
    end
  end

  def populate_database(iut)
    iut.save_key_value_pair("one", "one")
    iut.save_key_value_pair("two", "two")
    iut.save_key_value_pair("three", "three")
  end

  def delete_database
    FileUtils.rm_f(@db_name)
  end
end
