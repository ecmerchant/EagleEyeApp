class AccountsController < ApplicationController

  before_action :authenticate_user!, :except => [:regist]
  protect_from_forgery :except => [:regist]

  def setup
  end

  def regist
    if request.post? then
      logger.debug("====== Regist from Form Start =======")
      user = params[:user]
      password = params[:password]
      if User.find_by(email: user) == nil then
        #新規登録
        init_password = password
        tuser = User.create(email: user, password: init_password, admin_flg: false)
        Account.find_or_create_by(user: user)
        return
      end
    end
  end

end
