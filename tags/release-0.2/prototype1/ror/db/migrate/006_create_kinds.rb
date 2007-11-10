class CreateKinds < ActiveRecord::Migration
  def self.up
    create_table :kinds do |t|
    end
  end

  def self.down
    drop_table :kinds
  end
end
