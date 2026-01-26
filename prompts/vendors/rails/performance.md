# Rails Performance

Performance optimization techniques for Ruby on Rails applications.

## When to Apply

Activate this guide when:
- Optimizing slow Rails applications
- Fixing N+1 query problems
- Implementing caching strategies
- Improving database performance

---

## 1. N+1 Query Prevention

### Problem

```ruby
# ❌ N+1 queries
@posts = Post.all
@posts.each do |post|
  puts post.author.name  # Query for each post
end
```

### Solution: Eager Loading

```ruby
# ✓ Single query with includes
@posts = Post.includes(:author).all

# ✓ Nested associations
@posts = Post.includes(author: :profile, comments: :user)

# ✓ With conditions on association
@posts = Post.includes(:comments).where(comments: { approved: true })

# eager_load (LEFT OUTER JOIN)
@posts = Post.eager_load(:author).where(authors: { active: true })

# preload (separate queries)
@posts = Post.preload(:comments, :tags)
```

### Strict Loading

```ruby
# Raise error if N+1 detected
class ApplicationRecord < ActiveRecord::Base
  self.strict_loading_by_default = true
end

# Or per-query
Post.strict_loading.all

# Disable for specific associations
class Post < ApplicationRecord
  has_many :comments, strict_loading: false
end
```

---

## 2. Database Optimization

### Indexing

```ruby
# Migration
class AddIndexes < ActiveRecord::Migration[7.0]
  def change
    # Single column
    add_index :users, :email

    # Unique
    add_index :users, :email, unique: true

    # Composite
    add_index :orders, [:user_id, :created_at]

    # Partial index
    add_index :users, :email, where: "deleted_at IS NULL"

    # Concurrent (no lock)
    add_index :users, :email, algorithm: :concurrently
  end
end
```

### Query Optimization

```ruby
# ✓ Select only needed columns
User.select(:id, :name, :email).where(active: true)

# ✓ Use pluck for simple values
User.where(active: true).pluck(:email)

# ✓ Use find_each for large datasets
User.find_each(batch_size: 1000) do |user|
  process(user)
end

# ✓ Use exists? instead of count > 0
User.where(email: email).exists?

# ✓ Use size vs count vs length
collection.size   # Uses COUNT if not loaded, length if loaded
collection.count  # Always COUNT query
collection.length # Loads all records, then counts
```

### Raw SQL When Needed

```ruby
# Complex aggregations
Post.find_by_sql(<<-SQL)
  SELECT posts.*, COUNT(comments.id) as comments_count
  FROM posts
  LEFT JOIN comments ON comments.post_id = posts.id
  GROUP BY posts.id
  HAVING COUNT(comments.id) > 10
SQL

# Bulk updates
Post.where(draft: true).update_all(status: 'pending')
```

---

## 3. Caching

### Fragment Caching

```erb
<%# app/views/posts/index.html.erb %>
<% @posts.each do |post| %>
  <% cache post do %>
    <%= render post %>
  <% end %>
<% end %>

<%# With version %>
<% cache [post, current_user.admin?] do %>
  <%= render post %>
<% end %>

<%# Collection caching %>
<%= render partial: 'post', collection: @posts, cached: true %>
```

### Low-Level Caching

```ruby
class Post < ApplicationRecord
  def comments_count
    Rails.cache.fetch("#{cache_key_with_version}/comments_count") do
      comments.count
    end
  end
end

# With expiration
Rails.cache.fetch("posts/trending", expires_in: 1.hour) do
  Post.trending.limit(10).to_a
end

# Manual invalidation
Rails.cache.delete("posts/trending")
```

### Russian Doll Caching

```ruby
# Model
class Post < ApplicationRecord
  belongs_to :author, touch: true  # Updates author when post changes
  has_many :comments
end

class Comment < ApplicationRecord
  belongs_to :post, touch: true    # Updates post when comment changes
end
```

```erb
<%# Nested cache fragments %>
<% cache @author do %>
  <h1><%= @author.name %></h1>
  <% @author.posts.each do |post| %>
    <% cache post do %>
      <%= render post %>
      <% post.comments.each do |comment| %>
        <% cache comment do %>
          <%= render comment %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

### HTTP Caching

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])

    # ETag based caching
    fresh_when(@post)

    # Or with explicit control
    if stale?(@post, public: true, expires_in: 1.hour)
      render :show
    end
  end
end
```

---

## 4. Background Jobs

### Move Slow Operations

```ruby
# ❌ Slow - blocks request
class UsersController < ApplicationController
  def create
    @user = User.create!(user_params)
    UserMailer.welcome(@user).deliver_now  # Blocks!
    ExternalApi.sync_user(@user)           # Blocks!
  end
end

# ✓ Fast - background processing
class UsersController < ApplicationController
  def create
    @user = User.create!(user_params)
    UserMailer.welcome(@user).deliver_later
    SyncUserJob.perform_later(@user.id)
  end
end

# app/jobs/sync_user_job.rb
class SyncUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    ExternalApi.sync_user(user)
  end
end
```

---

## 5. Memory Optimization

### Avoid Loading All Records

```ruby
# ❌ Loads all records into memory
User.all.each { |u| process(u) }

# ✓ Batch processing
User.find_each { |u| process(u) }

# ✓ In batches with IDs
User.in_batches do |batch|
  batch.update_all(processed: true)
end
```

### Streaming Large Responses

```ruby
class ReportsController < ApplicationController
  def export
    headers['Content-Type'] = 'text/csv'
    headers['Content-Disposition'] = 'attachment; filename="export.csv"'

    response.stream.write(csv_header)

    User.find_each do |user|
      response.stream.write(user_to_csv(user))
    end
  ensure
    response.stream.close
  end
end
```

---

## 6. Query Profiling

### Development Tools

```ruby
# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.rails_logger = true
end
```

### Production Monitoring

```ruby
# Log slow queries
# config/initializers/slow_query_logger.rb
ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)

  if event.duration > 100 # ms
    Rails.logger.warn "Slow Query (#{event.duration.round(1)}ms): #{event.payload[:sql]}"
  end
end
```

### Explain Queries

```ruby
# View query plan
User.where(active: true).explain

# In console
User.where(active: true).explain(:analyze)
```

---

## 7. Configuration

### Production Settings

```ruby
# config/environments/production.rb

# Connection pooling
config.database_configuration["production"]["pool"] = ENV.fetch("RAILS_MAX_THREADS") { 5 }

# Asset caching
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}

# Action Mailer
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.perform_caching = false
```

### Database Configuration

```yaml
# config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  prepared_statements: true
  advisory_locks: false
```

## References

- [Rails Performance](https://guides.rubyonrails.org/caching_with_rails.html)
- [N+1 Queries](https://www.rorvswild.com/blog/2025/more-everyday-performance-rules-for-ruby-on-rails-developers)
- [Bullet Gem](https://github.com/flyerhzm/bullet)
