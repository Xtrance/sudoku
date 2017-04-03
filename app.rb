require "sinatra"
require "pry"
require "sinatra/activerecord"
require 'sinatra/flash'
require 'sinatra/base'
require "sinatra/cookies"
require "sinatra/config_file"
require "./models/user"
require "./models/game_counter"
require "./models/stash"
require "./models/game"
require "json"
require "pony"
require 'logger'


enable :static
enable :sessions

#config_file '/config/config.yml'

set :public_folder, File.dirname(__FILE__) + '/assets'

#if RACK_ENV="development"

#configure :development do
  #set :database, { adapter: "sqlite3", database: "sudoku_database.sqlite3" }
#end
#else
#configure :production do
  #set :database, { adapter: "sqlite3", database: File.expand_path("~/db/sudoku_database.sqlite3")  }
#end
#end
#configure :development do
 # set :database, { adapter: "postgresql", database: "sudoku_database", pool: 5, timeout: 5000 }
#end

#configure :production do
  #set :database, { adapter: "postgresql", database: "test_prod", pool: 5, timeout: 5000, username: 'deploy1', password: 'qwerty' }
#end

set :static_cache_control, [:public, {:no_store => 1}]

#db = ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/sudoku_database')



# #logs for production
# ::Logger.class_eval { alias :write :'<<' }
#   access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','access.log')
#   access_logger = ::Logger.new(access_log)
#   error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),':stage,log','error.log'),"a+")
#   error_logger.sync = true

# configure do
#     use ::Rack::CommonLogger, access_logger
#   end
 
#   before {
#     env["rack.errors"] =  error_logger
#   }  

before '/*' do
  @top_players_ten = User.all.order('scores desc').limit(10)
  
  @meta = Hash.new('/kontakte' => '', '/' => '', '/regeln' => '', '/rangliste' => '', '/sudoku-l%C3%B6sung' => '',)
  @meta['/kontakte'] = {'title' => 'Kontakt - Sudoku-Spielen.org', 'description' => 'Kontakt'}
  @meta['/'] =  {'title' => 'Sudoku online kostenlos spielen |  Sudoku-Spielen.org', 'description' => 'Sudoku online kostenlos spielen ohne Anmeldung. Mehr als 100,000 Rätsel. 5 Schwierigkeitsgrade. Sudoku für Handy. Sudoku ausdrucken.'}
  @meta['/regeln'] = {'title' => 'Sudoku Spielregeln', 'description' => 'Spielregeln für Sudoku online und auf Papier. Einfach, punktweise, mit Abbildungen und Erklärungen. Erlernen Sie die Grundlagen und spielen Sudoku online!'}
  @meta['/rangliste'] = {'title' => 'Rangliste von Sudoku Spielern', 'description' => 'Rangliste von besten Sudoku Spielern! Melden Sie sich an. Lösen Sie Puzzles von verschiedenem Schwierigkeitsgrad. Bekommen Sie Punkte. Gewinnen Sie! Jetzt auf PC oder Handy spielen.'}
  @meta['/sudoku-l%C3%B6sung'] = {'title' => 'Wie löst man Sudoku: Mittel, Methoden und Strategien', 'description' => 'Mittel, Methoden und Strategien für Sudoku Lösungen, für Anfänger und Fortgeschrittene. Wie spielt man and löst schwere Sudoku Rätsel.'}
  @meta['/datenschutzerklaerung'] = {'title' => 'Datenschutzerklärung (Disclaimer)', 'description' => 'Datenschutzerklärung (Disclaimer)'}
  @meta['/sudoku-geschichte'] = {'title' => 'Sudokugeschichte', 'description' => 'Wir bieten Sie an, dieses Spiel näher kennenzulernen und durch alle Phasen von Entwicklung ihrer Popularität zu gehen.'}
end


LEVELS_TABLE = {
  '35': 'easy', '40': 'medium',
  '45': 'hard', '50': 'expert',
  '55': 'insane'
}

def convert_month(date)
  if !date.match('Jan').nil?
    return date.sub(%r{Jan}, 'Jan')
  elsif !date.match('Feb').nil?
     return date.sub(%r{Feb}, 'Feb')
  elsif !date.match('Mar').nil?
     return date.sub(%r{Mar}, 'März')
  elsif !date.match('Apr').nil?
     return date.sub(%r{Apr}, 'Apr')
  elsif !date.match('May').nil?
     return date.sub(%r{May}, 'Mai')
  elsif !date.match('June').nil?
     return date.sub(%r{June}, 'Juni')
  elsif !date.match('July').nil?
     return date.sub(%r{July}, 'Juli')
  elsif !date.match('Aug').nil?
     return date.sub(%r{Aug}, 'Aug')
  elsif !date.match('Sept').nil?
     return date.sub(%r{Sept}, 'Sept')
  elsif !date.match('Oct').nil?
     return date.sub(%r{Oct}, 'Okt')
  elsif !date.match('Nov').nil?
     return date.sub(%r{Nov}, 'Nov')
  elsif !date.match('Dec').nil?
     return date.sub(%r{Dec}, 'Dez')
  end
end


helpers do
  def current_user
    if session[:uid].present?
      User.find(session[:uid])
    else
      return false
    end
  end

  def guest_scores
    if cookies[:guest_id]
      # @guest_user = User.find_by('name', cookies[:guest_id]).first
      @guest_user = User.where(name: cookies[:guest_id]).first
    else
      return false
    end
  end
end


not_found do
  status 404
  erb :notfound
end


get '/' do
  #@top_players = User.all.order('scores desc').limit(10)
  @top_players = User.where('created_at >= ? and created_at <= ?', Time.now.beginning_of_month, Time.now.end_of_month).order('scores desc').limit(10)
  @stashed_games = current_user ? current_user.stashes : []
  if !current_user
    CHARS = ('0'..'9').to_a
    guest_id = CHARS.sort_by { rand }.join[0...9]
    if !cookies[:guest_id]
      cookies[:guest_id] = guest_id
      @guest_user = User.new(name: guest_id, is_guest: 1, password: '123')
      @guest_user.save!
    end
  end
  if params[:stashed_game].present?
    load_stash = Stash.find(params[:stashed_game])
    if current_user
      if current_user.id == load_stash.user_id
        @stashed_game = load_stash
      end
    else
      redirect to('/not-found')
    end
  end
  @hidden = 'hidden'
  erb :index, :layout => :default
end


get '/kontakte' do
  #@top_players = User.all.order('scores desc').limit(25)
  erb :contacts, :layout => :default
end


get '/rangliste' do
  #@top_players = User.all.order('scores desc').limit(25)
  @top_players = User.where('created_at >= ? and created_at <= ?', Time.now.beginning_of_month, Time.now.end_of_month).order('scores desc').limit(25)
  erb :raiting, :layout => :default
end


get '/regeln' do
  erb :rules, :layout => :default
end


get '/losungstechniken' do
  erb :howto, :layout => :default
end

get '/sudoku-lösung' do
  erb :how_game, :layout => :default
end

get '/sudoku-geschichte' do
  erb :history, :layout => :default
end


get '/datenschutzerklaerung' do
  erb :policy, :layout => :default
end

get '/sitemap.xml' do
  File.read("sitemap.xml")
end

get '/robots.txt' do
  send_file 'robots.txt'
end

get '/indexold' do
  @top_players = User.all.order('scores desc')
  @stashed_games = current_user ? current_user.stashes : []
  if params[:stashed_game].present?
    @stashed_game = Stash.find(params[:stashed_game])
  end
  erb :indexold
end

post '/get-reiting' do
  if params[:type] == '1'
    @top_players = User.where('created_at >= ? and created_at <= ?', Time.now.beginning_of_month, Time.now.end_of_month).order('scores desc').limit(25)
    erb :get_raiting
  else
    @top_players = User.all.order('scores desc').limit(25)
    erb :get_raiting
  end
end


post '/check_email' do
  user = User.find_by_email(params[:param])
  if user
    content_type :json
    { 
      :status => 'EXIST'
    }.to_json
  else
    content_type :json
    { 
      :status => 'CLEAR'
    }.to_json
  end
end


post '/check_name' do
  user = User.find_by_name(params[:param])
  if user
    content_type :json
    { 
      :status => 'EXIST'
    }.to_json
  else
    content_type :json
    { 
      :status => 'CLEAR'
    }.to_json
  end
end


post '/restore' do
  user = User.find_by_email(params[:email])
  if user
    CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
    new_password = CHARS.sort_by { rand }.join[0...5]
    Pony.mail({
      :to => params[:email],
      :from => 'xtrance1991@gmail.com',
      :subject => 'Passwort-Wiederherstellung: Sudoku-spielen.org',
      :body => new_password,
      :via => :sendmail,
      :via_options => {
        :port => '25',
        :domain => 'sudoku-spielen.org',
        :location => '/usr/sbin/sendmail', # defaults to 'which sendmail' or '/usr/sbin/sendmail' if 'which' fails
        :arguments => '-t' # -t and -i are the defaults
      }
    })
    user.update_attribute(:password, new_password)

    content_type :json
    { 
      :status => 'OK'
    }.to_json
  else
    content_type :json
    { 
      :status => 'FAIL'
    }.to_json
  end
end


post '/send' do
  Pony.mail({
    :to => 'xtrance1991@gmail.com',
    :from => params[:email],
    :subject => params[:username],
    :body => params[:message],
    :via => :sendmail,
    :via_options => {
        :port => '25',
        :domain => 'sudoku-spielen.org',
        :location => '/usr/sbin/sendmail', # defaults to 'which sendmail' or '/usr/sbin/sendmail' if 'which' fails
        :arguments => '-t' # -t and -i are the defaults
      }
    }
  )
  content_type :json
  { 
    :status =>'OK',
    :data => {
      :email => params[:email],
      :name => params[:username],
      :message => params[:message]
    }
  }.to_json
end


post '/sign_up' do
  # создаём пользователя
  @user = User.new(name: params["name"], email: params["email"], password: params["password"])
  if @user.save
    # кладём id в сессию
    session[:uid] = @user.id
    # добавляем флэш об успешной регистрации
    flash[:notice] = 'Thanks for your sign up. Sign in succeffuly completed.'
  else
    # добавляем флэш об ошибке
    flash[:alert] = 'Sorry, error in your sign up data. Try again, please.'
  end
  # редиректим на главную
  redirect to('/')
end


post '/sign_in' do
  user = User.find_by_email(params[:email])
  if user && user.authenticate(params[:password])
    session[:uid] = user.id
    flash[:notice] = "Hello, #{user.name}! Welcome to sudoku game."
  else
    flash[:alert] = 'Error on sign in proccess.'
  end
  redirect to('/')
end


delete '/sign_out' do
  session.clear
  flash[:notice] = 'Sign out succeffuly completed. See you later.'
  redirect to('/')
end


post '/game/completed' do
  @game = Game.find(params[:game_id])
  if @game.complete == 1
    add_score = false
  else
    add_score = true
    if @game
      @game.complete = 1
      @game.save
    end
  end
  if current_user
    # обновляем очки
    user = User.find(current_user.id)
    if add_score
      scores = params[:scores].to_i
      user.scores = user.scores + scores
      user.save
    end
    # обновляем количество игр на уровне сложности
    game_counter = user.game_counter
    level = LEVELS_TABLE[ params[:level].to_sym ]
    game_counter[level] = user.game_counter[level] + 1
    game_counter.save
  else
    @guest_user = User.where(name: cookies[:guest_id]).first
    if add_score
      scores = params[:scores].to_i
      @guest_user.scores = @guest_user.scores + scores
      @guest_user.save
    end
    game_counter = @guest_user.game_counter
    level = LEVELS_TABLE[ params[:level].to_sym ]
    game_counter[level] = @guest_user.game_counter[level] + 1
    game_counter.save
    :ok
  end
end


post '/game/delete' do
  stash = Stash.find(params[:stash_id])
  if params[:stash_id] && stash
    Stash.destroy(params[:stash_id])
    content_type :json
    { :status => 'DELETED', :id => stash.id }.to_json
  else
    content_type :json
    { :status => 'FAILED' }.to_json
  end
end


post '/game/create' do
  @game = Game.new(complete: 0)
  if @game.save
    content_type :json
    { :status => 'CREATED', :game_id => @game.id }.to_json
  end
end


post '/game/stash' do
  if current_user
    user = User.find(current_user.id)
    params[:disabled_grid] = params[:disabled_grid].values
    params[:stashed_grid_numbers] = params[:stashed_grid_numbers].values.map { |array| array.map(&:to_i) }
    params[:right_solution] = params[:right_solution].values.map { |array| array.map(&:to_i) }
    stash = user.stashes.create(params)
    content_type :json
    { id: stash.id, created_at: convert_month(stash.created_at.strftime("%b %d, %H:%M")), scores: stash.scores, time: stash.time }.to_json
  else
    halt 401
  end
end
