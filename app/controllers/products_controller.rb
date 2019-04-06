class ProductsController < ApplicationController

  def show
    user = current_user.email
    @login_user = current_user
    @account = Account.find_or_create_by(user: user)
    @lists = nil
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
      if keyword != nil || store_id != nil || category_id != nil then
        if shop_id == "1" then
          #楽天市場
          Product.rakuten_search(user, condition)
        elsif shop_id == "2" then
          #ヤフーショッピング
          Product.yahoo_search(user, condition)
        end
      end
    end
    redirect_to products_show_path
  end

end
