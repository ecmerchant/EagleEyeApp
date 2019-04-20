class ListsController < ApplicationController

  require 'csv'

  def show
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)

    csv = nil
    @headers = Array.new
    File.open('app/others/amazon_new_listing_template.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end
    @lists = List.where(user: user, status: 'searching').limit(5)

    @body = Array.new
    @template = ListTemplate.where(user: user, list_type: '新規')

    @lists.each do |temp|
      thash = Hash.new
      @template.each do |ch|
        thash[ch.header] = ch.value
      end

      @headers[2].each do |col|
        case col
        when 'item_sku' then
          thash['item_sku'] = temp.product_id
        when 'standard_price' then
          thash['standard_price'] = temp.product.price
        when 'product-id' then
          thash['product-id'] = temp.product_id
        when 'external_product_id_type' then
          thash['external_product_id_type'] = 'JAN'
        when 'external_product_id' then
          thash['external_product_id'] = temp.product.jan
        when 'condition_type' then
          thash['condition_type'] = temp.condition
        when 'main_image_url' then
          thash['main_image_url'] = temp.product.image1
        when 'other_image_url1' then
          thash['other_image_url1'] = temp.product.image2
        when 'other_image_url2' then
          thash['other_image_url2'] = temp.product.image3
        when 'model' || 'part_number' then
          thash['model'] = temp.product.part_number
          thash['part_number'] = temp.product.part_number
        when 'brand_name' || 'manufacturer' then
          thash['brand_name'] = temp.product.brand
          thash['manufacturer'] = temp.product.brand
        when 'product_description' then
          thash['product_description'] = temp.product.description.gsub(/\r\n|\r|\n|\t/, " ")
        when 'item_name' then
          thash['item_name'] = temp.product.title
        when 'update_delete' then
          thash['update_delete'] = 'Update'
        else

        end
      end
      @body.push(thash)
    end

    respond_to do |format|
      format.html do
          #html用の処理を書く
      end
      format.csv do
        fname = "アマゾン出品ファイル_" + Time.now.strftime("%Y%m%D%H%M%S") + ".txt"
        send_data render_to_string, filename: fname, type: :csv
      end
    end
  end

  def regist
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    @lists = List.where(user: user, status: 'searching')
    @lists.update_all(
      status: 'listing'
    )

    @account.update(
      progress: "処理受付前"
    )
    redirect_to lists_check_path
  end

  def check

    user = current_user.email
    @login_user = current_user
    @account = Account.find_or_create_by(user: user)
    @shop_id = @account.selected_shop_id
    @lists = List.where(user: user, shop_id: @shop_id, status: "listing").page(params[:page]).per(100)
    @headers = Constants::HD

    respond_to do |format|
      format.html
        if request.post? then
          data = params[:product_del]
          logger.debug("======== DEL ===========")
          if data != nil then
            ext = File.extname(data.path)
            if ext == ".xls" || ext == ".xlsx" then
              logger.debug("=== delete ===")
              workbook = RubyXL::Parser.parse(data.path)
              worksheet = workbook[0]

              worksheet.each_with_index do |row, i|
                if i > 0 then
                  if row[0] == nil then break end
                  if row[0].value == nil then break end
                  ng = row[0].value.to_s

                  temp.where(asin: ng).update(
                    list_flg: false
                  )

                end
              end
            end
          end
          redirect_to lists_check_path
        end
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook[0]

        user = current_user.email
        @sheet.add_cell(0, 0, "削除ASIN")
        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "削除ASINテンプレート.xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end

  end

end
