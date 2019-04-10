class ProductSearchJob < ApplicationJob
  queue_as :product_search

  rescue_from(StandardError) do |exception|
    logger.debug("===== Standard Error Escape Active Job ======")
    logger.error exception
  end

  def perform(user, condition, shop_id)
    if shop_id == "1" then
      #楽天市場
      Product.rakuten_search(user, condition)
    elsif shop_id == "2" then
      #ヤフーショッピング
      Product.yahoo_search(user, condition)
    end
  end

end
