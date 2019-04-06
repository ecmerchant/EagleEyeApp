class Product < ApplicationRecord
  require 'open-uri'

  def self.rakuten_search(user, condition)


  end


  def self.yahoo_search(user, condition)
    logger.debug("-------------------------------------------")
    account = Account.find_by(user: user)
    if account != nil then
      if account.yahoo_app_id != nil then
        app_id = account.yahoo_app_id
      else
        app_id = ENV['YAHOO_APPID']
      end
    end

    query = condition[:keyword]
    category_id = condition[:category_id]
    store_id = condition[:store_id]

    (0..19).each do |num|
      offset = 50 * num

      endpoint = 'https://shopping.yahooapis.jp/ShoppingWebService/V1/itemSearch?appid=' + app_id.to_s + '&condition=new&availability=1&hits=50&offset=' + offset.to_s
      url = endpoint

      if query != nil then
        esc_query = URI.escape(query)
        url = url + '&query=' + esc_query.to_s
      end

      if category_id != nil then
        url = url + '&category_id=' + category_id.to_s
      end

      if store_id != nil then
        url = url + '&store_id=' + store_id.to_s
      end
      user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"
      charset = nil
      option = {
        "User-Agent" => user_agent
      }
      html = open(url, option) do |f|
        charset = f.charset
        f.read # htmlを読み込んで変数htmlに渡す
      end

      doc = Nokogiri::HTML.parse(html, nil, charset)
      hits = doc.xpath('//hit')

      if hits.length == 0 then break end

      product_list = Array.new
      category_list = Array.new
      chash = Hash.new

      data = nil
      hits.each do |hit|
        title = hit.xpath('./name').text
        description = hit.xpath('./description').text
        product_id = hit.xpath('./code').text
        temp = hit.xpath('./image')
        image1 = nil
        image2 = nil
        image3 = nil
        temp.each_with_index do |image, i|
          buf = image.xpath('./medium').text
          if i == 0 then
            image1 = buf
          elsif i == 1 then
            image2 = buf
          elsif i == 2
            image3 = buf
          end
        end
        price = hit.xpath('./price').text
        category_id = hit.xpath('./category/current/id').text
        category_name = hit.xpath('./category/current/name').text
        brand = hit.xpath('./brands/name').text
        part_number = hit.xpath('./model').text

        data = Hash.new
        data = {
          product_id: product_id,
          shop_id: "2",
          title: title,
          description: description,
          image1: image1,
          image2: image2,
          image3: image3,
          brand: brand,
          part_number: part_number,
          category_id: category_id,
          price: price
        }
        product_list << Product.new(data)
        if chash.has_key?(category_id) == false then
          category_list << Category.new(category_id: category_id, name: category_name, shop_id: "2")
          chash[category_id] = category_name
        end
      end

      if data != nil then
        cols = data.keys
        cols.delete_at(0)
        cols.delete_at(0)
        Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns: cols}
        Category.import category_list, on_duplicate_key_update: {constraint_name: :for_upsert_categories, columns: [:name]}
      end
    end
  end

end
