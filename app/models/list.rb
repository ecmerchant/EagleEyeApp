class List < ApplicationRecord
  has_one :product, foreign_key: 'product_id', primary_key: 'product_id'
  has_one :shop, primary_key: 'shop_id', foreign_key: 'shop_id'
end
