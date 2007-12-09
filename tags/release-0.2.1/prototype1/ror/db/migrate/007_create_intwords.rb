class CreateIntwords < ActiveRecord::Migration
  def self.up
    create_table :intwords do |t|
    end
  end

  def self.down
    drop_table :intwords
  end
end
