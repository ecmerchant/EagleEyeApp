class SearchCondition < ApplicationRecord
  has_one :shop, primary_key: 'shop_id', foreign_key: 'shop_id'
end
