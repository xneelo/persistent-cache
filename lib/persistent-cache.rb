require "persistent-cache/version"
require "sqlite3"
require "persistent-cache/storage_sqlite"
require "persistent-cache/storage_directory"
require "persistent-cache/storage_ram"

module Persistent
  class Cache
    STORAGE_SQLITE = 'sqlite' unless defined? STORAGE_SQLITE
    STORAGE_DIRECTORY = 'directory' unless defined? STORAGE_DIRECTORY
    STORAGE_RAM = 'ram' unless defined? STORAGE_RAM

    # Fresh is 1 day less than the bacula default job retention time. If this is configured differently, FRESH should be updated as well.
    FRESH = 15465600; FRESH.freeze

    attr_accessor :storage_details
    attr_accessor :storage
    attr_accessor :fresh
    attr_accessor :encoding

    def initialize(storage_details, fresh = FRESH, storage = STORAGE_SQLITE)
      raise ArgumentError.new("No storage details provided") if storage_details.nil? or storage_details == ""

      @storage = create_storage(storage, storage_details)
      @fresh = fresh
      @storage_details = storage_details

      raise ArgumentError.new("Unsupported storage type #{storage}}") if @storage.nil?
    end

    def set(key, value, timestamp)
      if value.nil?
        delete_entry(key)
      else
        save_key_value_pair(key, value, timestamp)
      end
    end

    def []=(key, value)
      if value.nil?
        delete_entry(key)
      else
        save_key_value_pair(key, value)
      end
    end

    def [](key)
      lookup_key(key)
    end

    def each(&_block)
      keys.each do |key|
        yield key, lookup_key(key)
      end
    end

    def size
      @storage.size
    end

    def keys
      @storage.keys    
    end

    def clear
      @storage.clear
    end

    def timestamp?(key)
      k = encode_if_requested(key)
      result = @storage.lookup_key(k)
      return nil if result.nil? or result[1].nil?
      Time.parse(result[1])
    end

    def key?(key)
      if @storage.keys
        @storage.keys.each do |k|
          return k if k == key
        end
      end
      return nil      
    end

    private

    def create_storage(storage, storage_details)
      return StorageSQLite.new(storage_details) if storage == STORAGE_SQLITE
      return StorageDirectory.new(storage_details) if storage == STORAGE_DIRECTORY
      return StorageRAM.new(storage_details) if storage == STORAGE_RAM
    end

    def encode_if_requested(key)
      return key.encode(@encoding) if (not @encoding.nil?) and (key.is_a?(String))
      key
    end

    def save_key_value_pair(key, value, timestamp = nil)
      k = encode_if_requested(key)
      @storage.delete_entry(k)
      @storage.save_key_value_pair(k, value, timestamp)
    end

    def lookup_key(key)
      k = encode_if_requested(key)
      result = @storage.lookup_key(k)
      return nil if nil_result?(result)
      return nil if stale_entry?(k, result)

      return result[0]
    end

    def stale_entry?(key, result)
      return false if @fresh.nil?

      timestamp = Time.parse(result[1])
      if ((Time.now - timestamp) > @fresh)
        delete_entry(key)
        return true
      end
      return false
    end

    def delete_entry(key)
      k = encode_if_requested(key)
      @storage.delete_entry(k)
    end

    def nil_result?(result)
      result.nil? or result[0].nil?
    end
  end
end
