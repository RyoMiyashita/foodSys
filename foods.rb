require 'sinatra'
require 'active_record'
require 'digest/md5'
require 'date'

set :environment, :production
set :sessions,
  expire_after: 7200,
  secret: 'gabagabasecretcodedesuw'


ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class User < ActiveRecord::Base
  has_many :foods
end

class Food < ActiveRecord::Base
  belongs_to :user
  has_many :details
end

class Detail < ActiveRecord::Base
  belongs_to :food
end

get '/' do
  redirect '/login'
end

get '/logout' do
  session.clear
  @title = 'logout'
  erb :logout
end

get '/login' do
  @title = 'login'
  erb :login
end

post '/login' do  # sessionでuserName埋める?
  code = 0
  data = nil
  message = ""

  userName = params[:user_name]
  userPass = params[:user_pass]

  if (userName.empty?)
    code = -21
    message = message + "UserNameが空欄です。"
  end
  if (userPass.empty?)
    code = -22
    message = message + "Passwordが空欄です。"
  end

  if code == 0
    user = User.find_by(user_name: userName)
    if user == nil
      code = -41
      message = "ユーザーが存在しないか、パスワードが間違っています。"
    else
      if user.algo == "1"
        trialHashed = Digest::MD5.hexdigest(user.salt + userPass)
        if trialHashed == user.hashed
          code = 1
          message = "ログイン成功"
        else
          code = -41
          message = "ユーザーが存在しないか、パスワードが間違っています。"
        end
      else
        code = -42
        message = "Not Found hash algorithm."
      end
    end
  end

  if code == 1
    session[:login_flag] = true
    session[:user_id] = user.id
    session[:user_name] = userName
  else
    session[:login_flag] = false
  end

  data = {
    code: code,
    data: data,
    message: message
  }
  data.to_json
end

get '/new_user' do
  @tilte = 'new_user'
  erb :new_user
end

post '/new_user' do
  code = 0
  data = nil
  message = ""

  userName = params[:user_name]
  userPass = params[:user_pass]
  userRePass = params[:user_repass]

  arrayUserName = User.pluck(:user_name)

  if (userName.empty?)
    code = -21
    message = message + "UserNameが空欄です。"
  end
  if (userPass.empty?)
    code = -22
    message = message + "Passwordが空欄です。"
  end
  if (userRePass.empty?)
    code = -23
    message = message + "Password再入力が空欄です。"
  end

  if code == 0
    if (userName.match(/[^a-zA-Z1-9_]/) == nil)
      if (userPass.match(/[^a-zA-Z1-9_]/) == nil)
        if (userPass == userRePass)
          if (arrayUserName.include?(userName))
            code = -31
            message ="すでに使用されているUserNameです。"
          else
            newUser = User.new
            newUser.id = ((User.last.nil? ? 0 : User.last.id) + 1)
            newUser.user_name = userName

            random = Random.new
            salt = Digest::MD5.hexdigest(random.bytes(20))
            hashed = Digest::MD5.hexdigest(salt + userPass)
            algo = 1

            newUser.salt = salt
            newUser.hashed = hashed
            newUser.algo = algo

            newUser.save
            code = 1
            message = "新規User作成 成功。ログインタブよりログインしてください。"
          end
        else
          code = -11
          message = "パスワード再入力が一致しません"
        end
      else
        code = -12
        message = "password : 半角英数字と_（アンダーバー）のみ使用可能"
      end
    else
      code = -13
      message = "username : 半角英数字と_（アンダーバー）のみ使用可能"
    end
  end

  data = {
    code: code,
    data: data,
    message: message
  }
  data.to_json
end

get '/menu' do
  if session[:login_flag] == true
    @userName = session[:user_name]
    @title = 'Home'
    erb :menu
  else
    redirect '/login'
  end
end

get '/user/edit' do
  if session[:login_flag] == true
    @userName = session[:user_name]
    @title = 'ユーザー編集'
    erb :user_edit
  else
    redirect '/login'
  end
end

post '/user/delete' do
  if session[:login_flag] == true
    id = session[:user_id]
    user = User.find(id)
    user.destroy
  end
  redirect '/logout'
end

get '/index' do
  if session[:login_flag] == true
    @userName = session[:user_name]
    @foods = Food.where(user_id: session[:user_id]).where.not(last_best_before_date: nil).order("last_best_before_date ASC")
    @foods += Food.where(user_id: session[:user_id]).where(last_best_before_date: nil)
    @title = '一覧'
    erb :foods_index
  else
    redirect '/login'
  end
end

get '/food/new' do
  if session[:login_flag] == true
    @title = '新規食品作成'
    @userName = session[:user_name]
    erb :new_food
  else
    redirect '/login'
  end
end

post '/food/new' do
  code = 0
  data = nil
  message = ""

  foodName = params[:food_name]
  foodCategory = params[:food_category]

  foodName = foodName.gsub(/<(.+?)>/, '&lt;\1&gt;')
  foodCategory = foodCategory.gsub(/<(.+?)>/, '&lt;\1&gt;')

  if code == 0
    newFood = Food.new
    id = ((Food.last.nil? ? 0 : Food.last.id) + 1)
    newFood.id = id
    newFood.user_id = session[:user_id]
    newFood.name = foodName
    newFood.category = foodCategory
    newFood.save
    data = id
    code = 1
    message = "success new Food"
  end

  data = {
    code: code,
    data: data,
    message: message
  }
  data.to_json
end

get '/details/edit/:id' do
  if session[:login_flag] == true
    @title = '食品詳細編集'
    @userName = session[:user_name]
    @food = Food.find(params[:id])
    @details = []
    @beforeDetails = Detail.where(food_id: params[:id])
    @beforeDetails.each_with_index do |item, i|
      @details[i] = {
        "id" => item.id,
        "number" => item.number,
        "best_before_date" => item.best_before_date.nil? ? nil : item.best_before_date.strftime('%Y %b %d (%a) %H:%M:%S')
      }
    end
    erb :edit_details
  else
    redirect '/login'
  end
end

post '/detail/edit/:id' do
  if session[:login_flag] == true
    food_id = params[:id]
    number = params[:number]
    best_before = params[:best_before]

    number = number.gsub(/<(.+?)>/, '&lt;\1&gt;')

    if best_before.empty?
    best_before = nil
    else
      best_before = DateTime.parse(best_before)
    end

    newDetail = Detail.new
    newDetail.id = ((Detail.last.nil? ? 0 : Detail.last.id) + 1)
    newDetail.food_id = food_id
    newDetail.number = number
    newDetail.best_before_date = best_before
    newDetail.save

    food = Food.find(food_id)
    arrayDetailsNumber = []
    arrayDetailsNumber = Detail.where(food_id: food_id).pluck(:number)

    food.total_number = 0
    arrayDetailsNumber.each do |num|
      food.total_number += num.to_i
    end

    targetDetail = Detail.where(food_id: food_id).where.not(number: -Float::INFINITY..0).order('best_before_date ASC').first

    food.last_best_before_date =  targetDetail.nil? ? nil : targetDetail.best_before_date

    food.save

    redirect '/details/edit/' + food_id
  else
    redirect '/login'
  end
end

post '/detail/number/' do
  number = params[:number].to_i
  detailId = params[:detailId].to_i

  editedDetail = Detail.find(detailId)

  editedDetail.number = number
  foodId = editedDetail.food_id
  editedDetail.save

  food = Food.find(foodId)
  arrayDetailsNumber = []
  arrayDetailsNumber = Detail.where(food_id: foodId).pluck(:number)
  puts arrayDetailsNumber

  food.total_number = 0
  arrayDetailsNumber.each do |num|
    food.total_number += num
  end

  targetDetail = Detail.where(food_id: foodId).where.not(number: -Float::INFINITY..0).order('best_before_date ASC').first

  food.last_best_before_date = targetDetail.nil? ? nil : targetDetail.best_before_date

  food.save

  data = {
    code: 1,
    data: foodId,
    message: "success"
  }
  data.to_json
end
