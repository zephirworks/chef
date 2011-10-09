#
# Author:: Andrea Campi (<andrea.campi@zephirworks.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Bundler.require 'fog'

class Chef
  class Checksum
    class Storage
      #
      # A backend for Chef::Checksum::Storage that uses the Fog gem to store
      # files on S3, Rackspace or any other storage service supported by Fog.
      #
      # To use this backend you need to add your service details and credentials
      # to your Chef server configuration file (e.g. /etc/chef/server.rb).
      #
      # For example, to configure the backend to use S3:
      #
      #   checksum_path :provider => 'AWS',
      #                 :aws_access_key_id => '<your access key>',
      #                 :aws_secret_access_key => '<your secret key>',
      #                 :directory => '<your bucket name>')
      #
      class Fog
        def initialize(config, checksum)
          @config = config.dup
          @dir = @config.delete(:directory)
          @checksum = checksum
        end

        attr_accessor :directory
        def directory
          return @directory if @directory

          @fog ||= ::Fog::Storage.new(@config)
          @directory = @fog.directories.get(@dir)
          raise "Bad" unless @directory

          @directory
        end

        def to_s
          "fog #{directory.key} #{@checksum}"
        end

        def commit(sandbox_file)
          directory.files.create(:key => @checksum, :body => File.read(sandbox_file))
          FileUtils.rm(sandbox_file)
        end

        def revert(original_committed_file_location)
          File.open(original_committed_file_location, "w") do |file|
            file.write directory.files.get(@checksum).body
          end
        end

        def retrieve
          ret = directory.files.get(@checksum)
          raise Errno::ENOENT unless ret
          ret.body
        end

        # Deletes the file backing this checksum from the on-disk repo.
        # Purging the checksums is how users can get back to a valid state if
        # they've deleted files, so we silently swallow Errno::ENOENT here.
        def purge
          directory.files.destroy(@checksum)
        rescue Excon::Errors::NotFound
          true
        end
      end
    end
  end
end
