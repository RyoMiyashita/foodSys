require 'sinatra'
require 'active_record'
require 'digest/md5'

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

            nowTime = Time.now
            strDT = nowTime.strftime("%Y-%m-%d %H:%M:%S")

            newUser.created_at = strDT
            newUser.updated_at = strDT

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
    @foods = Food.where(user_id: session[:user_id])
    @title = '一覧'
    erb :foods_index
  else
    redirect '/login'
  end
end
