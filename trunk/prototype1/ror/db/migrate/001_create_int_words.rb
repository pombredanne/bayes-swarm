class CreateIntWords < ActiveRecord::Migration
  def self.up
    create_table :int_words do |t|
    end
  end

  def self.down
    drop_table :int_words
  end
end
