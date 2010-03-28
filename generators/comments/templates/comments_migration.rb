class CommentsMigration < ActiveRecord::Migration
  def self.up
    create_table :comment_topics do |t|
      t.string :name
    end

    create_table :comments do |t|
      t.text :content
      t.integer :topic_id
    end
  end
  
  def self.down
    drop_table :comment_topics
    drop_table :comments
  end
end
