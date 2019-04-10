class Shop < ApplicationRecord
  belongs_to :list, primary_key: 'shop_id', foreign_key: 'shop_id', optional: true
end
