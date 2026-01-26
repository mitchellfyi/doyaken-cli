# Rails Design Patterns

Service objects, form objects, and architectural patterns for Rails.

## When to Apply

Activate this guide when:
- Organizing business logic
- Refactoring fat models/controllers
- Implementing complex workflows
- Building maintainable Rails applications

---

## 1. Service Objects

### When to Use

- Logic spans multiple models
- Complex business processes
- External API interactions
- Logic that doesn't fit in models

### Basic Pattern

```ruby
# app/services/users/register.rb
module Users
  class Register
    def initialize(params)
      @params = params
    end

    def call
      user = User.new(@params)

      if user.save
        send_welcome_email(user)
        track_signup(user)
        Result.success(user)
      else
        Result.failure(user.errors)
      end
    end

    private

    def send_welcome_email(user)
      UserMailer.welcome(user).deliver_later
    end

    def track_signup(user)
      Analytics.track('user_signup', user_id: user.id)
    end
  end
end

# Usage in controller
class UsersController < ApplicationController
  def create
    result = Users::Register.new(user_params).call

    if result.success?
      redirect_to dashboard_path, notice: 'Welcome!'
    else
      @user = User.new(user_params)
      @user.errors.merge!(result.errors)
      render :new
    end
  end
end
```

### Result Object

```ruby
# app/services/result.rb
class Result
  attr_reader :value, :errors

  def initialize(success:, value: nil, errors: nil)
    @success = success
    @value = value
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(errors)
    new(success: false, errors: errors)
  end
end
```

### Callable Pattern

```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(...)
    new(...).call
  end
end

# app/services/orders/process.rb
module Orders
  class Process < ApplicationService
    def initialize(order)
      @order = order
    end

    def call
      ActiveRecord::Base.transaction do
        charge_payment
        update_inventory
        send_confirmation
        Result.success(@order)
      end
    rescue PaymentError => e
      Result.failure(e.message)
    end
  end
end

# Usage
Orders::Process.call(order)
```

---

## 2. Form Objects

### When to Use

- Forms span multiple models
- Complex validation logic
- Virtual attributes needed

### Pattern

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :password, :string
  attribute :company_name, :string
  attribute :terms_accepted, :boolean

  validates :name, :email, :password, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      company = Company.create!(name: company_name)
      @user = company.users.create!(
        name: name,
        email: email,
        password: password
      )
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def user
    @user
  end
end

# Controller
class RegistrationsController < ApplicationController
  def create
    @form = RegistrationForm.new(registration_params)

    if @form.save
      sign_in(@form.user)
      redirect_to dashboard_path
    else
      render :new
    end
  end

  private

  def registration_params
    params.require(:registration).permit(
      :name, :email, :password, :company_name, :terms_accepted
    )
  end
end
```

---

## 3. Query Objects

### When to Use

- Complex database queries
- Reusable query logic
- Chainable scopes

### Pattern

```ruby
# app/queries/products_query.rb
class ProductsQuery
  def initialize(relation = Product.all)
    @relation = relation
  end

  def call
    @relation
  end

  def active
    @relation = @relation.where(active: true)
    self
  end

  def in_stock
    @relation = @relation.where('inventory_count > 0')
    self
  end

  def in_category(category)
    @relation = @relation.where(category: category)
    self
  end

  def priced_between(min, max)
    @relation = @relation.where(price: min..max)
    self
  end

  def search(term)
    @relation = @relation.where('name ILIKE ?', "%#{term}%")
    self
  end

  def ordered_by_popularity
    @relation = @relation.order(sales_count: :desc)
    self
  end
end

# Usage
ProductsQuery.new
  .active
  .in_stock
  .in_category('electronics')
  .priced_between(100, 500)
  .ordered_by_popularity
  .call
```

---

## 4. Presenter/Decorator Pattern

### When to Use

- View-specific formatting
- Complex display logic
- Keep models clean of view code

### Pattern

```ruby
# app/presenters/user_presenter.rb
class UserPresenter
  def initialize(user, view_context)
    @user = user
    @h = view_context
  end

  def full_name
    "#{@user.first_name} #{@user.last_name}"
  end

  def avatar
    if @user.avatar.attached?
      @h.image_tag @user.avatar, class: 'avatar'
    else
      @h.image_tag 'default_avatar.png', class: 'avatar'
    end
  end

  def membership_badge
    case @user.plan
    when 'premium'
      @h.content_tag :span, 'Premium', class: 'badge badge-gold'
    when 'pro'
      @h.content_tag :span, 'Pro', class: 'badge badge-silver'
    else
      nil
    end
  end

  def joined_at
    @user.created_at.strftime('%B %d, %Y')
  end

  def method_missing(method, *args, &block)
    @user.send(method, *args, &block)
  end
end

# Helper
module ApplicationHelper
  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self)
    yield presenter if block_given?
    presenter
  end
end

# View
<% present(@user) do |user| %>
  <%= user.avatar %>
  <h1><%= user.full_name %></h1>
  <%= user.membership_badge %>
  <p>Member since <%= user.joined_at %></p>
<% end %>
```

---

## 5. Policy Objects

### When to Use

- Authorization logic
- Access control decisions
- Permission checking

### Pattern

```ruby
# app/policies/post_policy.rb
class PostPolicy
  def initialize(user, post)
    @user = user
    @post = post
  end

  def show?
    @post.published? || owner?
  end

  def create?
    @user.present?
  end

  def update?
    owner? || @user.admin?
  end

  def destroy?
    owner? || @user.admin?
  end

  def publish?
    owner? && @post.draft?
  end

  private

  def owner?
    @user == @post.author
  end
end

# Controller
class PostsController < ApplicationController
  def update
    @post = Post.find(params[:id])
    policy = PostPolicy.new(current_user, @post)

    unless policy.update?
      redirect_to root_path, alert: 'Not authorized'
      return
    end

    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end
end
```

---

## 6. Concerns

### When to Use

- Shared behavior across models
- Reusable model features
- Cross-cutting concerns

### Pattern

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(term) {
      where("#{table_name}.name ILIKE ?", "%#{term}%")
    }
  end

  class_methods do
    def searchable_fields(*fields)
      @searchable_fields = fields
    end

    def search(term)
      fields = @searchable_fields || [:name]
      conditions = fields.map { |f| "#{table_name}.#{f} ILIKE ?" }
      where(conditions.join(' OR '), *Array.new(fields.size, "%#{term}%"))
    end
  end
end

# Usage
class Product < ApplicationRecord
  include Searchable
  searchable_fields :name, :description, :sku
end

Product.search('keyboard')
```

---

## 7. Directory Structure

```
app/
├── controllers/
├── models/
├── views/
├── services/           # Business logic
│   ├── application_service.rb
│   ├── users/
│   │   ├── register.rb
│   │   └── authenticate.rb
│   └── orders/
│       ├── create.rb
│       └── process.rb
├── forms/              # Form objects
│   ├── registration_form.rb
│   └── checkout_form.rb
├── queries/            # Query objects
│   ├── products_query.rb
│   └── users_query.rb
├── presenters/         # View presenters
│   ├── user_presenter.rb
│   └── order_presenter.rb
├── policies/           # Authorization
│   ├── post_policy.rb
│   └── comment_policy.rb
└── jobs/               # Background jobs
```

## References

- [Rails Guides](https://guides.rubyonrails.org/)
- [Design Patterns in Ruby](https://www.scoutapm.com/blog/rails-design-patterns)
