class Product < ApplicationRecord
  belongs_to :list, primary_key: 'product_id', foreign_key: 'product_id', optional: true

  require 'open-uri'
  require 'rakuten_web_service'

  def self.rakuten_search(user, condition)
    account = Account.find_by(user: user)
    search_id = condition[:search_id]
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

    min_price = condition[:min_price].to_i
    max_price = condition[:max_price].to_i

    if min_price > 0 && max_price == 0 then
      search_condition[:minPrice] = min_price
    elsif min_price > 0 && max_price > min_price then
      search_condition[:minPrice] = min_price
      search_condition[:maxPrice] = max_price
    elsif min_price == 0 && max_price > 0 then
      search_condition[:maxPrice] = max_price
    end
    logger.debug(search_condition)
    results = RakutenWebService::Ichiba::Item.search(search_condition)

    item_num = results.count
    num = 0
    logger.debug("===============================")
    logger.debug(item_num)
    if item_num > 0 then
      #検索結果からアイテム取り出し
      res = Hash.new
      counter = 0
      begin
        logger.debug("---")
        checker = Hash.new
        product_list = Array.new
        listing = Array.new

        results.each do |result|
          url = result['itemUrl']
          product_id = result['itemCode'].gsub(':','_')
          image1 = result['mediumImageUrls'][0]
          if image1 != nil then
            image1 = image1.gsub('?_ex=128x128', '')
          end
          image2 = result['mediumImageUrls'][1]
          if image2 != nil then
            image2 = image2.gsub('?_ex=128x128', '')
          end
          image3 = result['mediumImageUrls'][2]
          if image3 != nil then
            image3 = image3.gsub('?_ex=128x128', '')
          end
          name = result['itemName']
          price = result['itemPrice']

          category_id = result['genreId']
          description = result['itemCaption']
          mpn = nil

          condition = "New"
          if name.include?('中古') || description.include?('中古') then
            condition = "Used"
          end

          tag_ids = result['tagIds']
          tag_info = Array.new
          brand = nil
=begin
          tag_ids.each do |tag|
            logger.debug("====== Tag =========")
            logger.debug(tag)
            qurl = "https://app.rakuten.co.jp/services/api/IchibaTag/Search/20140222?format=json&tagId=" + tag.to_s + "&applicationId=" + app_id
            logger.debug(qurl)
            html = open(qurl) do |f|
              f.read # htmlを読み込んで変数htmlに渡す
            end
            logger.debug(html)
            group_name = /"tagGroupName":"([\s\S]*?)"/.match(html)
            if group_name != nil then
              group_name = group_name[1]
              if group_name == "メーカー" then
                brand = /"tagName":"([\s\S]*?)"/.match(html)[1]
                break
              end
            end
          end

          logger.debug("========== Access To Rakuten ============")
          charset = nil
          code = nil
          user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100'
          begin
            html = open(url, "User-Agent" => user_agent) do |f|
              charset = f.charset
              f.read # htmlを読み込んで変数htmlに渡す
            end
            code = /<span class="item_number">([\s\S]*?)<\/span>/.match(html)
            if code != nil then
              code = code[1]
            end
          rescue OpenURI::HTTPError => error
            logger.debug("--------- HTTP Error ------------")
            logger.debug(error)
          end
=end
          jan = nil
          code = nil

          if code != nil then
            if code.length == 13 then
              jan = code
            end
          end

          if jan != nil then
            logger.debug("============ Product ===============")
            search_condition = {
              keyword: jan,
            }
            response = RakutenWebService::Ichiba::Product.search(search_condition)
            response.each do |info|
              if info['brandName'] != nil then
                brand = info['brandName']
              end
              if info['productNo'] != nil then
                mpn = info['productNo']
              end
              logger.debug(brand)
              logger.debug(mpn)
              break
            end
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
            jan: jan,
            part_number: mpn,
            description: description,
            category_id: category_id,
            brand: brand
          }

          if checker.key?(product_id) == false && product_id != nil then
            num += 1
            product_list << Product.new(res)
            listing << List.new(user: user, product_id: product_id, shop_id:  "1", status: "searching", condition: condition, search_id: search_id)
            checker[product_id] = name
            account.update(
              progress: "取得済み " + num.to_s + "件"
            )
          end
        end
        sleep(0.5)

        if res != nil then
          cols = res.keys
          cols.delete_at(0)
          cols.delete_at(0)
          Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns: cols}
          List.import listing, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:status, :condition, :search_id]}
          account.update(
            progress: "取得中 " + num.to_s + "件取得済み"
          )
        end
        counter += 1
        if counter > 29 then
          break
        end
        results = results.next_page
      end while results.has_next_page?
    end
    account.update(
      progress: "取得完了 全" + num.to_s + "件取得"
    )
  end


  def self.yahoo_search(user, condition)
    account = Account.find_by(user: user)
    search_id = condition[:search_id]
    if account != nil then
      if account.yahoo_app_id != nil then
        app_id = account.yahoo_app_id
      else
        app_id = ENV['YAHOO_APPID']
      end
    end

    query = condition[:keyword]
    dcategory_id = condition[:category_id]
    store_id = condition[:store_id]

    dnum = 0
    (0..19).each do |num|
      logger.debug(num)
      offset = 50 * num
      endpoint = 'https://shopping.yahooapis.jp/ShoppingWebService/V1/itemSearch?appid=' + app_id.to_s + '&condition=new&availability=1&hits=50&offset=' + offset.to_s
      endpoint2 = 'https://shopping.yahooapis.jp/ShoppingWebService/V1/itemLookup?appid=' + app_id.to_s + "&responsegroup=large"

      min_price = condition[:min_price].to_i
      max_price = condition[:max_price].to_i

      if min_price > 0 && max_price == 0 then
        endpoint = endpoint + '&price_from=' + min_price.to_s
      elsif min_price > 0 && max_price > min_price then
        endpoint = endpoint + '&price_from=' + min_price.to_s
        endpoint = endpoint + '&price_to=' + max_price.to_s
      elsif min_price == 0 && max_price > 0 then
        endpoint = endpoint + '&price_to=' + max_price.to_s
      end

      url = endpoint

      if query != nil then
        esc_query = URI.escape(query)
        url = url + '&query=' + esc_query.to_s
      end

      if dcategory_id != nil then
        url = url + '&category_id=' + dcategory_id.to_s
      end

      if store_id != nil then
        url = url + '&store_id=' + store_id.to_s
      end
      user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"
      charset = nil
      option = {
        "User-Agent" => user_agent
      }

      logger.debug(url)
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

        durl  = endpoint2 + "&itemcode=" + product_id
        charset = nil
        html2 = open(durl, option) do |f|
          charset = f.charset
          f.read # htmlを読み込んで変数htmlに渡す
        end
        logger.debug(durl)
        logger.debug("========== detail =============")
        doc2 = Nokogiri::HTML.parse(html2, nil, charset)

        temp = doc2.xpath('//hit')
        image1 = nil
        image2 = nil
        image3 = nil

        image1 = temp.xpath('./image/medium').text
        images = temp.xpath('./relatedimages/image')
        images.each_with_index do |image, i|
          if i == 0 then
            image2 = image.xpath('./medium').text
          elsif i == 1 then
            image3 = image.xpath('./medium').text
          end
        end

        if image1 != nil then
          image1 = image1.gsub('/g/', '/n/')
        end

        if image2 != nil then
          image2 = image2.gsub('/g/', '/n/')
        end

        if image3 != nil then
          image3 = image3.gsub('/g/', '/n/')
        end

        price = hit.xpath('./price').text
        category_id = hit.xpath('./category/current/id').text
        category_name = hit.xpath('./category/current/name').text
        brand = hit.xpath('./brands/name').text
        part_number = hit.xpath('./model').text
        jan = hit.xpath('./jancode').text

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
          jan: jan,
          part_number: part_number,
          category_id: category_id,
          price: price
        }
        if title != nil then
          product_list << Product.new(data)
          dnum += 1
          account.update(
            progress: "取得済み " + dnum.to_s + "件"
          )

          if product_id != nil then
            listing << List.new(user: user, product_id: product_id, shop_id:  "2", status: "searching", condition: "New", search_id: search_id)
            if chash.has_key?(category_id) == false then
              category_list << Category.new(category_id: category_id, name: category_name, shop_id: "2")
              chash[category_id] = category_name
            end
          end
        end
      end

      if data != nil then
        cols = data.keys
        cols.delete_at(0)
        cols.delete_at(0)
        account.update(
          progress: "取得中 " + dnum.to_s + "件取得済み"
        )
        Product.import product_list, on_duplicate_key_update: {constraint_name: :for_upsert_products, columns: cols}
        List.import listing, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:status, :condition, :search_id]}
        Category.import category_list, on_duplicate_key_update: {constraint_name: :for_upsert_categories, columns: [:name]}
      end
      logger.debug("============ CHECK ================")
      logger.debug(url)
      tcheck = /totalResultsReturned="([\s\S]*?)"/.match(html)
      if tcheck != nil then
        logger.debug("============ END ================")
        tcheck = tcheck[1].to_i
        logger.debug(tcheck)
        if tcheck < 50 then break end
      end
    end
    account.update(
      progress: "取得完了 全" + dnum.to_s + "件取得"
    )
  end

end
