class Product < ApplicationRecord
  belongs_to :list, primary_key: 'product_id', foreign_key: 'product_id', optional: true

  require 'open-uri'
  require 'rakuten_web_service'

  def self.rakuten_search(user, condition)
    account = Account.find_by(user: user)
    if account != nil then
      if account.rakuten_app_id != nil then
        app_id = account.rakuten_app_id
      else
        app_id = ENV['RAKUTEN_APP_ID']
      end
    end

    RakutenWebService.configure do |c|
      c.application_id = ENV['RAKUTEN_APP_ID']
    end

    search_condition = Hash.new
    search_condition = {
      keyword: condition[:keyword],
      shopCode: condition[:store_id],
      genreId: condition[:category_id]
    }

    results = RakutenWebService::Ichiba::Item.search(search_condition)

    item_num = results.count

    if item_num > 0 then
      #検索結果からアイテム取り出し
      res = Hash.new
      counter = 0
      while results.has_next_page?
        checker = Hash.new
        product_list = Array.new
        listing = Array.new

        results.each do |result|
          url = result['itemUrl']
          product_id = result['itemCode'].gsub(':','_')
          image1 = result['mediumImageUrls'][0]
          image2 = result['mediumImageUrls'][1]
          image3 = result['mediumImageUrls'][2]
          name = result['itemName']
          price = result['itemPrice']

          category_id = result['genreId']
          description = result['itemCaption']
          mpn = nil

          condition = "New"
          if name.include?('中古') || description.include?('中古') then
            condition = "Used"
          end
          res = Hash.new
          res = {
            shop_id: "1",
            product_id: product_id,
            title: name,
            price: price,
            image1: image1,
            image2: image2,
            image3: image3,
            part_number: mpn,
            description: description,
            category_id: category_id,
            brand: nil
          }

          if checker.key?(product_id) == false then
            product_list << Product.new(res)
            listing << List.new(user: user, product_id: product_id, shop_id:  "1", status: "searching", condition: "New")
            checker[product_id] = name
          end
        end
        sleep(0.5)

        if res != nil then
          cols = res.keys
          cols.delete_at(0)
          cols.delete_at(0)
          Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns: cols}
          List.import listing, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:status, :condition]}
        end
        counter += 1
        if counter > 9 then
          break
        end
        results = results.next_page
      end
    end

  end


  def self.yahoo_search(user, condition)
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
      listing = Array.new
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
        listing << List.new(user: user, product_id: product_id, shop_id:  "2", status: "searching", condition: "New")
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
        List.import listing, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:status, :condition]}
        Category.import category_list, on_duplicate_key_update: {constraint_name: :for_upsert_categories, columns: [:name]}
      end
    end
  end

end
