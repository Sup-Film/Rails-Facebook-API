class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :email
      t.string :image
      t.string :oauth_token
      t.datetime :oauth_expires_at

      t.timestamps
    end
  end
end
