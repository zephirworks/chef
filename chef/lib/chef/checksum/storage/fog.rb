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
      class Fog
        def initialize(base_dir, checksum)
          @fog = ::Fog::Storage.new(:provider => 'AWS', :aws_access_key_id => '44CF9590006BF252F707', :aws_secret_access_key => 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV', :host => 'prova.dev', :port => '3002', :scheme => 'http')
          @directory = @fog.directories.get('chef')
          @checksum = checksum
        end

        def to_s
          "fog #{@directory.key} #{@checksum}"
        end

        def commit(sandbox_file)
          @directory.files.create(:key => @checksum, :body => File.read(sandbox_file))
          FileUtils.rm(sandbox_file)
        end

        def revert(original_committed_file_location)
          File.open(original_committed_file_location, "w") do |file|
            file.write @directory.files.get(@checksum).body
          end
        end

        def retrieve
          ret = @directory.files.get(@checksum)
          raise Errno::ENOENT unless ret
          ret.body
        end

        # Deletes the file backing this checksum from the on-disk repo.
        # Purging the checksums is how users can get back to a valid state if
        # they've deleted files, so we silently swallow Errno::ENOENT here.
        def purge
          @directory.files.destroy(@checksum)
        rescue Excon::Errors::NotFound
          true
        end
      end
    end
  end
end
