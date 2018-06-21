class SubsumeEndpointType < ActiveRecord::Migration[5.1]
  def up
    EndpointType.find_each { |et| et.endpoints.update_all(ep_type: et.endpoint_class) }
  end
end
