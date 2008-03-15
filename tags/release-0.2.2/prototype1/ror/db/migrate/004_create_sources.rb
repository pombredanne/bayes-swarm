class CreateSources < ActiveRecord::Migration
  def self.up
    create_table :sources do |t|
    end
  end

  def self.down
    drop_table :sources
  end
end
