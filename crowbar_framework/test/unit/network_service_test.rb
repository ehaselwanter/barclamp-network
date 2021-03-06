# Copyright 2012, Dell 
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 
require 'test_helper'
 
class NetworkServiceTest < ActiveSupport::TestCase

  # Test creation
  test "network_create: success" do
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, "public")
  end


  # Test failed network creation due to missing router_pref
  test "network_create: missing router_pref" do
    net_service = NetworkService.new(Rails.logger)
    http_error, network = net_service.network_create(
        "public2",
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        nil,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network creation due to missing router_ip
  test "network_create: missing router_ip" do
    net_service = NetworkService.new(Rails.logger)
    http_error, network = net_service.network_create(
        "public3",
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        nil )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end
  

  # Test failed network creation due to missing ip range
  test "network_create: missing no ip range" do
    net_service = NetworkService.new(Rails.logger)
    http_error, network = net_service.network_create(
        "public4",
        "intf0",
        "192.168.122.0/24",
        "false",
        nil,
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test retrieval by name
  test "network_get: by name success" do
    net_name="public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    # Get by name
    network = get_a_network(net_service, net_name)
    assert_equal net_name, network.name, "Expected to get network with name #{net_name}, got network with name #{network.name}"
  end


  # Test retrieval by id
  test "network_get: by id success" do
    net_name="public"
    net_service = NetworkService.new(Rails.logger)
    network = create_a_network(net_service, net_name)

    # Get by id
    id=network.id
    network = get_a_network(net_service, id)
    assert_equal id, network.id, "Expected to get network with id #{id}, got network with id #{network.id}"
  end
  

  # Test retrieval of non-existant object
  test "network_get: non-existant network" do
    net_service = NetworkService.new(Rails.logger)

    # Get by name
    http_error, network = net_service.network_get("zippityDoDa")
    assert_not_nil network, "Expected to get error message, but got nil"
    assert_equal 404, http_error, "Expected to get HTTP error code 404, got HTTP error code: #{http_error}, #{network}"
  end


  # Test adding an ip range
  test "network_update: add ip range" do
    net_name="public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }, "admin": { "start": "192.168.122.128", "end": "192.168.122.149" }}'),
        5,
        "192.168.122.1" )
    assert_equal 200, http_error, "Expected to get HTTP error code 200, got HTTP error code: #{http_error}, #{network}"

    ip_range = IpRange.where( :name => "admin", :network_id => network.id )
    assert_not_nil ip_range, "Expecting ip_range, got nil"
  end


  # Test removing an ip range
  test "network_update: remove ip range" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }}'),
        5,
        "192.168.122.1" )
    assert_equal 200, http_error, "Expected to get HTTP error code 200, got HTTP error code: #{http_error}, #{network}"

    ip_ranges = IpRange.where( :name => "dhcp", :network_id => network.id )
    assert_equal 0, ip_ranges.size, "Expected to get 0 ip_ranges, got #{ip_ranges}"
  end


  # Test removing all IP ranges from a network
  test "network_update: remove all ip ranges" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        '',
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test updating to an IP range that has no start
  test "network_update: ip range with no start" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test updating to an IP range that has no end
  test "network_update: ip range with no end" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network update due to missing router_pref
  test "network_update: missing router_pref" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        nil,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network update due to missing router_ip
  test "network_update: missing router_ip" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        nil )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end
  

  # Test deletion of non-existant network
  test "network_delete: non-existant network" do
    delete_nonexistant_network( NetworkService.new(Rails.logger), "zippityDoDa")
  end


  # Test deletion
  test "network_delete: success" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    # Delete by name
    http_error, msg = net_service.network_delete(net_name)
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{msg}"

    # Verify deletion
    delete_nonexistant_network(net_service, net_name)
  end


  private
  # Create a Network
  def create_a_network(net_service, name)
    # HACK!  We should remove this line when conduits are prepopulated in the system
    # TODO
    # conduit = NetworkTestHelper.create_a_conduit()

    http_error, network = net_service.network_create(
        name,
        "intf0",
        "192.168.122.0/24",
        "false",
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        "192.168.122.1" )
    assert_not_nil network
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{network}"
    network
  end


  # Retrieve a Network
  def get_a_network(net_service, id)
    http_error, network = net_service.network_get(id)
    assert_not_nil network
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{network}"
    network
  end


  # Try to delete a Network that does not exist
  def delete_nonexistant_network( net_service, id )
    http_error, msg = net_service.network_delete(id)
    assert_not_nil msg, "Expected to get error message, but got nil"
    assert_equal 404, http_error, "HTTP error code returned: #{http_error}, #{msg}"
  end
end
