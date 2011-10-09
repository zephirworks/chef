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

require 'chef/checksum/storage/filesystem'
require 'chef/checksum/storage/fog'

class Chef
  class Checksum
    class Storage
      class << self
        def for(checksum)
          config = Chef::Config.checksum_path
          if config.is_a?(Hash) && config.has_key?(:provider)
            Storage::Fog.new(config, checksum)
          else
            Storage::Filesystem.new(config, checksum)
          end
        end
      end
    end
  end
end
