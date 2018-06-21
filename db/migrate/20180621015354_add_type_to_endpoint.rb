class AddTypeToEndpoint < ActiveRecord::Migration[5.1]
  def change
    add_column :endpoints, :ep_type, :int
    add_index :endpoints, :ep_type
  end
end
