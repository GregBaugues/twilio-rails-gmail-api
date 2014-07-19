class ModifyTokens < ActiveRecord::Migration

  def change
    remove_column :tokens, :auth_token
    add_column :tokens, :access_token, :string
    add_column :tokens, :refresh_token, :string
    add_column :tokens, :expires_at, :datetime
  end

end
