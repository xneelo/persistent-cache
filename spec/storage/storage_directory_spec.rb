require 'spec_helper'

describe Persistent::StorageDirectory do
  before :each do
    @test_key = "testkey"
    @test_value = "testvalue"
    @db_name = get_database_name
    @test_dir = "#{@db_name}/#{@test_key}"
    @test_file = "#{@test_dir}/#{Persistent::StorageDirectory::CACHE_FILE}"
    @test_data = "some data\nmoredata\n\n"

    delete_database
    @iut = Persistent::StorageDirectory.new(@db_name)
  end

  context "when constructed" do
    it "should create the database if it does not exist" do
      result = File.exists?(@db_name)
      expect(result).to eq(true)
    end

    it "should propagate errors that are raised when failing to create a database" do
      delete_database
      expect(FileUtils).to receive(:makedirs).and_raise RuntimeError.new("testing")
      expect {
        @iut = Persistent::StorageDirectory.new(@db_name)
      }.to raise_error RuntimeError
    end

    it "should use the existing database if it does exist" do
      delete_database
      FileUtils.makedirs([@db_name])
      test_file = "#{@db_name}/hello"
      `touch #{test_file}`
      Persistent::StorageDirectory.new(@db_name)
      expect(File.exist?(test_file)).to eq(true)
    end

    it "should have a database" do
      expect(@iut.is_a?(Persistent::StorageDirectory)).to eq(true)
    end

    it "should raise an ArgumentError if storage details have not been provided" do
      expect {
        Persistent::StorageDirectory.new(nil)
      }.to raise_error(ArgumentError)
    end
  end

  context "when asked to store a key value pair" do
    it "should create a directory named the same as the key, in the storage root, if that directory does not exist, and store the value in a file called CACHE_FILE" do
      setup_test_entry
      expect(read_file_content(@test_file)).to eq(@test_data)
    end

    it "should default to storing the current time as the first line of the catalogue" do
      now = Time.now
      FileUtils.rm_f(@test_dir)
      @iut.save_key_value_pair(@test_key, @test_data)
      read_file_timestamp(@test_file) == now.to_s
    end

    it "should store a time specified as the first line of the catalogue" do
      time = Time.now - 2500
      FileUtils.rm_f(@test_dir)
      @iut.save_key_value_pair(@test_key, @test_data, time)
      expect(read_file_timestamp(@test_file)).to eq(time.to_s)
    end

    it "should overwrite the existing key/value pair if they already exist" do
      FileUtils.rm_f(@test_dir)
      @iut.save_key_value_pair(@test_key, "old data")
      @iut.save_key_value_pair(@test_key, @test_data)
      expect(File.exists?(@test_dir)).to eq(true)
      expect(File.exists?(@test_file)).to eq(true)
      expect(read_file_content(@test_file)).to eq(@test_data)
    end

    it "should raise an ArgumentError if the key is not a string" do
      expect {
        @iut.save_key_value_pair(1234, @test_data)
      }.to raise_error ArgumentError
    end

    it "should raise an ArgumentError if a key is requested that traverses above the storage root" do      
      expect {
        @iut.lookup_key("/../../secure-stuff-i-should-not-have-access-to")
      }.to raise_error(ArgumentError)
      expect {
        @iut.lookup_key(".")
      }.to raise_error(ArgumentError)
    end

    it "should raise an ArgumentError if the value is not a string" do
      expect {
        @iut.save_key_value_pair(@test_key, 1234)
      }.to raise_error ArgumentError
    end

    it "should store the value exactly as given, regardless of newlines" do
      @iut.save_key_value_pair(@test_key, "some data")
      expect(@iut.lookup_key(@test_key)[0][0]).to eq("some data")

      @iut.save_key_value_pair(@test_key, "some data\n")
      expect(@iut.lookup_key(@test_key)[0][0]).to eq("some data\n")

      @iut.save_key_value_pair(@test_key, "some data\n\n")
      expect(@iut.lookup_key(@test_key)[0][0]).to eq("some data\n\n")

      @iut.save_key_value_pair(@test_key, "\nline 1\n23456\n\n\nsome data\n")
      expect(@iut.lookup_key(@test_key)[0][0]).to eq("\nline 1\n23456\n\n\nsome data\n")
    end
  end

  context "When looking up a value given its key" do
    it "should retrieve the contents of the catalogue file from the database, excluding the timestamp" do
      setup_test_entry
      result = @iut.lookup_key(@test_key)
      expect(result[0][0]).to eq(@test_data)
    end

    it "should retrieve the timestamp of the revision from the database" do
      now = Time.now
      setup_test_entry
      result = @iut.lookup_key(@test_key)
      expect(result[0][1]).to eq(now.to_s)
    end

    it "should return an empty array if a key is not in the database" do
      setup_test_entry
      result = @iut.lookup_key("thiskeyshouldnotexist")
      expect(result).to eq([])
    end

    it "should raise an ArgumentError if the key is not a string" do
      expect {
        @iut.lookup_key(1234)
      }.to raise_error ArgumentError
    end
  end

  context "when asked to delete an entry" do
    it "should not raise an error if the directory that results from the hash is not present" do
      @iut.delete_entry("thiskeyshouldnotexist")
    end

    it "should delete the directory that results from the hash if it is present" do
      setup_test_entry
      @iut.delete_entry(@test_key)
      expect(@iut.lookup_key(@test_key)).to eq([])
      expect(File.exists?(@test_dir)).to eq(false)
      expect(File.exists?(@test_file)).to eq(false)
    end

    it "should raise an ArgumentError if the key is not a string" do
      expect {
        @iut.delete_entry(1234)
      }.to raise_error ArgumentError
    end
  end

  context "when asked the size of the database" do
    it "should return 0 if the database has no entries" do
      expect(@iut.size).to eq(0)
    end

    it "should return the number of entries" do
      populate_database
      expect(@iut.size).to eq(3)
    end

    it "should return 0 if the database does not exist" do
      delete_database
      expect(@iut.size).to eq(0)
    end
  end

  context "when asked for the keys in the database" do
    it "should return an empty array if there are no entries in the database" do
      expect(@iut.keys).to eq([])
    end

    it "should return the keys (directories) in the database" do
      populate_database
      expect(@iut.keys).to eq([["one"], ["three"], ["two"]])
    end

    it "should return the keys in a sorted array" do
      populate_database
      expect(@iut.keys).to eq([["one"], ["three"], ["two"]])
    end

    it "should not return the storage root itself" do
      populate_database
      @iut.keys.each do |key|
        expect((key == "")).to eq(false)
        expect((key == "/")).to eq(false)
      end
    end

    it "should return the keys in an array, with each key in its own sub-array" do
      populate_database
      expect(@iut.keys.is_a?(Array)).to eq(true)
      expect(@iut.keys[0].is_a?(Array)).to eq(true)
      expect(@iut.keys[0][0].is_a?(String)).to eq(true)
    end
  end

  context "when asked to clear the database" do
    it "should not delete the database root directory" do
      setup_test_entry
      @iut.clear
      expect(File.exists?(@test_file)).to eq(false)
      expect(File.exists?(@test_dir)).to eq(false)
      expect(File.exist?(@iut.storage_root)).to eq(true)
    end

    it "should delete all directories in the database" do
      populate_database
      @iut.clear
      expect(@iut.size).to eq(0)
    end
  end

  context "when asked about the path to a key's cache value file" do
    it "should return nil if the key is not in the cache" do
      expect(@iut.get_value_path(@test_key)).to eq(nil)
    end

    it "should return the path to the key's cache value file if the key is in the cache" do
      @iut.save_key_value_pair(@test_key, @test_data)
      expect(@iut.get_value_path(@test_key)).to eq(@test_file)
    end

    it "should raise an ArgumentError if the key is not a string" do
      expect {
        @iut.get_value_path(123)
      }.to raise_error ArgumentError
    end
  end

  def populate_database
    @iut.save_key_value_pair("one", "one")
    @iut.save_key_value_pair("two", "two")
    @iut.save_key_value_pair("three", "three")
  end

  def setup_test_entry
    FileUtils.rm_f(@test_dir)
    @iut.save_key_value_pair(@test_key, @test_data)
    expect(File.exists?(@test_dir)).to eq(true)
    expect(File.exists?(@test_file)).to eq(true)
  end

  def delete_database
    FileUtils.rm_rf(@db_name)
    expect(File.exists?(@db_name)).to eq(false)
  end

  def read_file_data(file)
    File.read(file).split("\n")
  end

  def read_file_timestamp(file)
    result = File.read(file)
    result.lines.to_a[0..0].join.split("\n")[0]
  end

  def read_file_content(file)
    result = File.read(file)
    result.lines.to_a[1..-1].join
  end
end
