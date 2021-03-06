class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.integer :subject_id
      t.integer :object_id
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
