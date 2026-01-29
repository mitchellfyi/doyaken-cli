# Rails API Development

Building REST APIs with Ruby on Rails.

## When to Apply

Activate this guide when:
- Building API-only Rails applications
- Creating JSON APIs
- Implementing API versioning
- Handling API authentication

---

## 1. API Setup

### API-Only Application

```ruby
# config/application.rb
module MyApi
  class Application < Rails::Application
    config.api_only = true
  end
end
```

### Base Controller

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_request

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def authenticate_request
        authenticate_or_request_with_http_token do |token, options|
          @current_user = User.find_by(api_token: token)
        end
      end

      def current_user
        @current_user
      end

      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { errors: exception.record.errors }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
```

---

## 2. API Versioning

### URL Versioning

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
      resources :posts
    end

    namespace :v2 do
      resources :users
      resources :posts
    end
  end
end
```

### Header Versioning

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    scope module: :v1, constraints: ApiVersion.new('v1', true) do
      resources :users
    end

    scope module: :v2, constraints: ApiVersion.new('v2') do
      resources :users
    end
  end
end

# lib/api_version.rb
class ApiVersion
  def initialize(version, default = false)
    @version = version
    @default = default
  end

  def matches?(request)
    @default || request.headers['Accept']&.include?("application/vnd.myapi.#{@version}")
  end
end
```

---

## 3. Serialization

### Jbuilder

```ruby
# app/views/api/v1/users/show.json.jbuilder
json.data do
  json.id @user.id
  json.type 'user'
  json.attributes do
    json.email @user.email
    json.name @user.name
    json.created_at @user.created_at.iso8601
  end
  json.relationships do
    json.posts @user.posts do |post|
      json.id post.id
      json.title post.title
    end
  end
end
```

### Active Model Serializers

```ruby
# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :created_at

  has_many :posts

  def created_at
    object.created_at.iso8601
  end
end

# Controller
class UsersController < Api::V1::BaseController
  def show
    user = User.find(params[:id])
    render json: user
  end

  def index
    users = User.all
    render json: users, each_serializer: UserSerializer
  end
end
```

### Manual Serialization

```ruby
# app/serializers/user_serializer.rb
class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      id: @user.id,
      email: @user.email,
      name: @user.name,
      created_at: @user.created_at.iso8601,
      posts: @user.posts.map { |p| PostSerializer.new(p).as_json }
    }
  end

  def self.collection(users)
    users.map { |u| new(u).as_json }
  end
end

# Controller
render json: { data: UserSerializer.new(@user).as_json }
```

---

## 4. Authentication

### Token Authentication

```ruby
# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_request, only: [:create]

      def create
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = user.generate_api_token
          render json: { token: token, user: UserSerializer.new(user).as_json }
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      def destroy
        current_user.regenerate_api_token
        head :no_content
      end
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  def generate_api_token
    regenerate_api_token
    api_token
  end
end
```

### JWT Authentication

```ruby
# app/services/jwt_service.rb
class JwtService
  SECRET = Rails.application.credentials.jwt_secret

  def self.encode(payload)
    payload[:exp] = 24.hours.from_now.to_i
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, algorithm: 'HS256')[0]
  rescue JWT::DecodeError
    nil
  end
end

# Controller
def authenticate_request
  header = request.headers['Authorization']
  token = header&.split(' ')&.last

  decoded = JwtService.decode(token)
  @current_user = User.find(decoded['user_id']) if decoded
rescue
  render json: { error: 'Unauthorized' }, status: :unauthorized
end
```

---

## 5. Error Handling

### Consistent Error Format

```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_error
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
  end

  private

  def handle_error(exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))

    render json: {
      error: {
        message: 'Internal server error',
        code: 'internal_error'
      }
    }, status: :internal_server_error
  end

  def not_found(exception)
    render json: {
      error: {
        message: exception.message,
        code: 'not_found'
      }
    }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: {
      error: {
        message: 'Validation failed',
        code: 'validation_error',
        details: exception.record.errors.as_json
      }
    }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render json: {
      error: {
        message: exception.message,
        code: 'bad_request'
      }
    }, status: :bad_request
  end
end
```

---

## 6. Pagination

### Pagy

```ruby
# app/controllers/api/v1/posts_controller.rb
class PostsController < Api::V1::BaseController
  include Pagy::Backend

  def index
    @pagy, @posts = pagy(Post.all, items: 20)

    render json: {
      data: PostSerializer.collection(@posts),
      meta: {
        current_page: @pagy.page,
        total_pages: @pagy.pages,
        total_count: @pagy.count,
        per_page: @pagy.items
      }
    }
  end
end
```

### Cursor Pagination

```ruby
def index
  posts = Post.order(id: :desc)

  if params[:cursor]
    posts = posts.where('id < ?', params[:cursor])
  end

  posts = posts.limit(20)

  render json: {
    data: PostSerializer.collection(posts),
    meta: {
      next_cursor: posts.last&.id
    }
  }
end
```

---

## 7. Rate Limiting

### Rack::Attack

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle all requests by IP
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # Throttle login attempts
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/api/v1/sessions' && req.post?
      req.ip
    end
  end

  # Throttle by API token
  throttle('req/token', limit: 1000, period: 1.hour) do |req|
    req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
  end
end

# config/application.rb
config.middleware.use Rack::Attack
```

---

## 8. API Response Helpers

```ruby
# app/controllers/concerns/api_response.rb
module ApiResponse
  def json_response(object, status = :ok, options = {})
    render json: object, status: status, **options
  end

  def paginated_response(pagy, collection, serializer = nil)
    data = serializer ? serializer.collection(collection) : collection

    render json: {
      data: data,
      meta: pagination_meta(pagy)
    }
  end

  def error_response(message, status = :bad_request, code: nil, details: nil)
    render json: {
      error: {
        message: message,
        code: code || status.to_s,
        details: details
      }.compact
    }, status: status
  end

  private

  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.items
    }
  end
end
```

## References

- [Rails API Guide](https://guides.rubyonrails.org/api_app.html)
- [JWT Authentication](https://jwt.io/)
- [API Best Practices](https://zuplo.com/learning-center/ruby-on-rails-api-dev-best-practices)
