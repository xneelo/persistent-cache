# Persistent::Cache

[![Gem Version](https://badge.fury.io/rb/persistent-cache.png)](https://badge.fury.io/rb/persistent-cache)
[![Build Status](https://travis-ci.org/evangraan/persistent-cache.svg?branch=master)](https://travis-ci.org/evangraan/persistent-cache)
[![Coverage Status](https://coveralls.io/repos/github/evangraan/persistent-cache/badge.svg?branch=master)](https://coveralls.io/github/evangraan/persistent-cache?branch=master)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/4157799e2f2b4102bade0bd543e5cbbc)](https://www.codacy.com/app/ernst-van-graan/persistent-cache?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=evangraan/persistent-cache&amp;utm_campaign=Badge_Grade)

Persistent cache behaves like a hash, with a pluggable back-end. Currently sqlite3, file system directory and RAM back-ends are provided. The cache defaults to type STORAGE_SQLITE

Values in the cache have a default freshness period of 15465600 ms. This can be configured in the cache initializer. Setting fresh = nil indicates that data remains fresh for-ever. Each user of the cache may have his own independent freshness value. Not though that accessing a stale entry deletes it from the cache. You can use timestamp?(key) to read the timestamp of an entry. If stale data is requested from the cache, nil is returned. Data is marshalled before storage. If a key is not found in the cache, nil is returned. Setting the value of a key in the cache to nil deletes the entry. If required, creation time of an entry can be specified using set(key, value, timestamp)

Note that when using a back-end that requires marshalling (e.g. sqlite) the string encoding for []= and [] needs to be the same (e.g. UTF-8, US-ASCII, etc.) If the coding does not match, [] will not be able to find the entry during lookup and will return nil. See the section on 'Encoding' below for more detail.

This gem was sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## StorageSQLite

Updates to the cache are written to the sqlite3 storage, with SQL driver timeout set to 30 seconds.

## StorageDirectory

Keys are required to be strings that are valid for use as directory names. The cache then stores from a storage root (configured in the StorageDirector constructor) with a subdirectory for each key, and a file called 'cache' for the value. The first line in the cache file is the timestamp of the entry.

When a StorageDirectory is used, it can be asked whether a key is present and what the path to a cache value is using:

    get_value_path(key)

    key_cached?(key)

## StorageRAM

Updates to the cache are stored in RAM using a hash.

## Installation

Add this line to your application's Gemfile:

    gem 'persistent-cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install persistent-cache

## Usage

    cache = Persistent::Cache.new("/tmp/my-persistent-cache", 3600) # 1 hour freshness

    cache["testkey"] = "testvalue"
    puts cache["testkey"] # testvalue

    cache["testkey"] = "newvalue"
    puts cache["testkey"] # newvalue

    cache["testkey"] = nil
    puts cache["testkey"] #

    cache["testkey"] = "one"
    cache["testkey2"] = "two"
    cache["testkey3"] = 3

    cache.each do |key|
      puts "#{key} - #{cache[key]}"
    end

    #testkey - one
    #testkey2 - two
    #testkey3 - 3

    puts cache.size # 3

    puts cache.keys
    #testkey
    #testkey2
    #testkey3

    cache.clear # []

    puts cache.size #0

    cache = Persistent::Cache.new("/tmp/my-persistent-cache") # 15465600 (179 days) freshness

    cache = Persistent::Cache.new("/tmp/my-persistent-cache", nil) # for-ever fresh

    cache = Persistent::Cache.new("/tmp/directory-cache", nil, Persistent::Cache::STORAGE_DIRECTORY)

    cache.set("mykey", "myvalue", Time.now) # explicitly set creation time

    cache = Persistent::Cache.new("cache-name", nil, Persistent::Cache::STORAGE_RAM)

    # Using .key?
    cache = Persistent::Cache.new("cache-name", 1)
    cache[1] = 2
    cache[1]
    # 2
    sleep 2
    cache.key?(1)
    # 1
    cache[1]
    # nil
    cache.key?(1)
    # nil

## Encoding

Note that when using a back-end that requires marshalling (e.g. sqlite) the string encoding for []= and [] needs to be the same (e.g. UTF-8, US-ASCII, etc.) If the coding does not match, [] will not be able to find the entry during lookup and will return nil. See the section on 'Encoding' below for more detail.

The easiest way to accomplish this with a ruby script is by adding the following shell directive at the top of your main.rb
  # encoding: utf-8

If you'd like persistent cache to rather store keys using an encoding of your preference, after initialization set the encoding explicitly using:
    cache.encoding = Encoding::UTF_8

## Contributing

Please send feedback and comments to the authors at:

Ernst van Graan <ernstvangraan@gmail.com>
