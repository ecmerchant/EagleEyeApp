class ProductsController < ApplicationController

  def show
    user = current_user.email
    @login_user = current_user
    @account = Account.find_or_create_by(user: user)
    @shop_id = @account.selected_shop_id
    @lists = List.where(user: user, shop_id: @shop_id).where('(status = ?) OR (status = ?)', "searching", "before_listing").page(params[:page]).per(3000)
    @headers = Constants::HD
  end

  def explain
    user = current_user.email
    @login_user = current_user
    @account = Account.find_or_create_by(user: user)
  end

  def search
    user = current_user.email
    if request.post? then
      shop_id = params[:shop_id]
      keyword = params[:keyword]
      store_id = params[:store_id]
      category_id = params[:category_id]
      min_price = params[:min_price]
      max_price = params[:max_price]
      condition = {
        keyword: keyword,
        store_id: store_id,
        category_id: category_id,
        min_price: min_price,
        max_price: max_price
      }
      @account = Account.find_or_create_by(user: user)

      if keyword != nil || store_id != nil || category_id != nil then
        @account.update(
          selected_shop_id: shop_id,
          search_start: Time.now,
          last_keyword: keyword,
          last_store_id: store_id,
          last_category_id: category_id,
          last_min_price: min_price,
          last_max_price: max_price,
          progress: "処理受付しました　進捗表示は画面を更新してください"
        )
        temp = SearchCondition.create(
          user: user,
          shop_id: shop_id,
          keyword: keyword,
          store_id: store_id,
          category_id: category_id,
          min_price: min_price,
          max_price: max_price,
        )
        search_id = temp.id
        condition[:search_id] = search_id
        List.where(user: user, status: 'searching').update_all(
          status: 'reject'
        )
        ProductSearchJob.perform_later(user, condition, shop_id)
      end
      redirect_to products_show_path
    else
      #get の場合
      @login_user = current_user
      @headers = {
        id: "検索ID",
        shop_id: "検索店舗",
        keyword: "キーワード",
        store_id: "ショップID",
        category_id: "カテゴリID",
        min_price: "最低価格",
        maxPrice: "最高価格"
      }
      @searches = SearchCondition.where(
        user: user
      ).page(params[:page]).per(30)

    end
  end


  def setup
    @login_user = current_user
    user = current_user.email

    @account = Account.find_or_create_by(user: user)
    @headers = Array.new
    @template = ListTemplate.where(user: user, shop_id: 3, list_type: '新規')

    @headers2 = Array.new
    @template2 = ListTemplate.where(user: user, shop_id: 2, list_type: '新規')

    @groups = FeedProduct.group(:group).pluck(:group)
    @feed_select = FeedProduct.where(group: @account.selected_group).group(:feed_type).pluck(:feed_type)

    File.open('app/others/amazon_new_listing_header.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end

    File.open('app/others/yahoo_listing_header.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers2.push(row)
      end
    end

    if request.post? then
      if params[:commit] == "アマゾン設定" then
        data = params[:text]
        data.each do |key, value|
          tp = ListTemplate.find_or_create_by(user: user, shop_id: 3, list_type: '新規', header: key)
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

  def update
    if request.post? then
      user = current_user.email
      data = params[:text]
      data.each do |key, value|
        tp = ListTemplate.find_or_create_by(user: user, shop_id: 2, list_type: '新規', header: key)
        tp.update(
          value: value
        )
      end
    end
    redirect_to products_setup_path
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

  def check
    user = current_user.email
    @login_user = current_user
    @account = Account.find_or_create_by(user: user)
    @shop_id = @account.selected_shop_id
    search_id = params[:search_id]
    logger.debug(search_id)
    @lists = List.where(user: user, search_id: search_id.to_s).page(params[:page]).per(100)

    @headers = Constants::HD
  end

end
