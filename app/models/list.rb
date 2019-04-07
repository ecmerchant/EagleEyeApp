class List < ApplicationRecord
  has_one :product, foreign_key: 'product_id', primary_key: 'product_id'
end
