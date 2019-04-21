class PricesController < ApplicationController

  def edit
    user = current_user.email
    @prices = Price.where(user: user).order("original_price ASC NULLS LAST")
    @login_user = current_user

    if request.post? then
      data = params[:price_edit]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xls" || ext == ".xlsx" then

          temp = Price.where(user: current_user.email)
          if temp != nil then
            temp.delete_all
          end
          logger.debug("=== UPLOAD ===")

          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook[0]
          worksheet.each_with_index do |row, i|
            if row[0].value == nil then break end
            if i > 0 then
              from = row[0].value.to_i
              to = row[1].value.to_i
              Price.find_or_create_by(
                user: user,
                original_price: from,
                convert_price: to
              )
            end
          end
        end
      end
      redirect_to prices_edit_path
    end
  end

  def template
    user = current_user.email
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook[0]

        @sheet.add_cell(0, 0, "仕入価格")
        @sheet.add_cell(0, 1, "販売価格")
        @sheet.add_cell(1, 0, 0)
        @sheet.add_cell(1, 1, 100)
        (1..100).each do |n|
          @sheet.add_cell(1 + n, 0, 5000 * n)
          @sheet.add_cell(1 + n, 1, 6000 * n)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "価格設定テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end


end
