class AddEmailToTokens < ActiveRecord::Migration
  def change
    add_column :tokens, :email, :string
    remove_column :tokens, :access_token
    add_column :tokens, :token, :string
  end
end
