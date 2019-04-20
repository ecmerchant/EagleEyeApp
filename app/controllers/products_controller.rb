class ProductsController < ApplicationController

  def show
    user = current_user.email
    @login_user = current_user
    @account = Account.find_or_create_by(user: user)
    @shop_id = @account.selected_shop_id
    @lists = List.where(user: user, shop_id: @shop_id, status: "searching").page(params[:page]).per(100)
    @headers = Constants::HD

  end

  def search
    if request.post? then
      user = current_user.email
      shop_id = params[:shop_id]
      keyword = params[:keyword]
      store_id = params[:store_id]
      category_id = params[:category_id]
      condition = {
        keyword: keyword,
        store_id: store_id,
        category_id: category_id
      }
      @account = Account.find_or_create_by(user: user)

      if keyword != nil || store_id != nil || category_id != nil then
        @account.update(
          selected_shop_id: shop_id,
          search_start: Time.now,
          progress: "処理受付"
        )
        List.where(user: user, status: 'searching').update_all(
          status: 'reject'
        )
        ProductSearchJob.perform_later(user, condition, shop_id)
      end
    end
    redirect_to products_show_path
  end


  def setup
    @login_user = current_user
    user = current_user.email

    @account = Account.find_or_create_by(user: user)
    @headers = Array.new
    @template = ListTemplate.where(user: user, shop_id: "3", list_type: '新規')
    @groups = FeedProduct.group(:group).pluck(:group)
    @feed_select = FeedProduct.where(group: @account.selected_group).group(:feed_type).pluck(:feed_type)

    File.open('app/others/amazon_new_listing_header.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end
    if request.post? then
      if params[:commit] == "設定" then
        data = params[:text]
        data.each do |key, value|
          tp = ListTemplate.find_or_create_by(user: user, shop_id: "3", list_type: '新規', header: key)
          tp.update(
            value: value
          )
        end
      else
        group = params[:top_category]
        @account.update(
          selected_group: group
        )
        @feed_select = FeedProduct.where(group: @account.selected_group).group(:feed_type).pluck(:feed_type)
      end
    end
  end

  def import
    if request.post? then
      data = params[:category_import]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          FeedProduct.all.delete_all
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook[0]
          worksheet.each_with_index do |row, index|
            if index > 0 then
              if row[0] == nil then break end
              group = row[0].value
              ftype = row[1].value
              name = row[2].value
              FeedProduct.find_or_create_by(
                group: group,
                feed_type: ftype,
                name: name
              )
            end
          end
        end
      end
    end
    redirect_to root_url
  end

end
