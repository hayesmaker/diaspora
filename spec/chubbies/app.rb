module Chubbies
  require 'active_record'
  require 'diaspora-client'

  def self.reset_db
    `rm -f #{File.expand_path('../chubbies.sqlite3', __FILE__)}`
    ActiveRecord::Base.establish_connection(
        :adapter => "sqlite3",
        :database  => "chubbies.sqlite3"
    )

    ActiveRecord::Schema.define do
      create_table :resource_servers do |t|
        t.string :client_id,     :limit => 40,  :null => false
        t.string :client_secret, :limit => 40,  :null => false
        t.string :host,          :limit => 127, :null => false
        t.timestamps
      end
      add_index :resource_servers, :host, :unique => true

      create_table :access_tokens do |t|
        t.integer :user_id, :null => false
        t.integer :resource_server_id, :null => false
        t.string  :access_token, :limit => 40, :null => false
        t.string  :refresh_token, :limit => 40, :null => false
        t.string  :uid, :limit => 40, :null => false
        t.datetime :expires_at
        t.timestamps
      end
      add_index :access_tokens, :user_id, :unique => true
      create_table :users do |t|
        t.timestamps
      end
    end
  end

  self.reset_db

  class User < ActiveRecord::Base
    has_one :access_token, :class_name => "DiasporaClient::AccessToken", :dependent => :destroy
  end

  DiasporaClient.config do |d|
    d.private_key_path = File.dirname(__FILE__) + "/chubbies.private.pem"
    d.public_key_path = File.dirname(__FILE__) + "/chubbies.public.pem"
    d.test_mode = true
    d.application_url = "http://localhost:9292"
  end

  class App < DiasporaClient::App
    def current_user
      User.first
    end

    def redirect_path
      '/callback'
    end

    def after_oauth_redirect_path
      '/account?id=1'
    end

    get '/account' do
      if params['id'] && user = User.where(:id => params['id']).first
        if user.access_token
          begin 
            @resource_response = user.access_token.token.get("/api/v0/me")
            haml :response
          rescue OAuth2::AccessDenied 
            "Token invalid"
          end
        else
          "No access token."
        end
      else
        "No user with id #{params['id']}"
      end
    end

    get '/new' do
      @user = User.create
      haml :home
    end

    get '/manifest.json' do
      {
        "name"         => "Chubbies",
        "description"  => "The best way to chub.",
        "homepage_url" => "http://localhost:9292/",
        "icon_url"     => "#",
        "public_key"   => DiasporaClient.public_key
      }.to_json
    end
    get '/reset' do
      Chubbies.reset_db
    end

    post '/register' do
      DiasporaClient::ResourceServer.create!(params)
    end
  end
end