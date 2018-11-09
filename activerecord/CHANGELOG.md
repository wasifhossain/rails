*   Bump minimum PostgreSQL version to 9.3.

    *Yuji Yaginuma*

*   Add an `:if_not_exists` option to `create_table`.

    Example:

        create_table :posts, if_not_exists: true do |t|
          t.string :title
        end

    That would execute:

        CREATE TABLE IF NOT EXISTS posts (
          ...
        )

    If the table already exists, `if_not_exists: false` (the default) raises an
    exception whereas `if_not_exists: true` does nothing.

    *fatkodima*, *Stefan Kanev*

*   Defining an Enum as a Hash with blank key, or as an Array with a blank value, now raises an `ArgumentError`.

    *Christophe Maximin*

*   Adds support for multiple databases to `rails db:schema:cache:dump` and `rails db:schema:cache:clear`.

    *Gannon McGibbon*

*   `update_columns` now correctly raises `ActiveModel::MissingAttributeError`
    if the attribute does not exist.

    *Sean Griffin*

*   Add support for hash and url configs in database hash of `ActiveRecord::Base.connected_to`.

    ````
    User.connected_to(database: { writing: "postgres://foo" }) do
      User.create!(name: "Gannon")
    end

    config = { "adapter" => "sqlite3", "database" => "db/readonly.sqlite3" }
    User.connected_to(database: { reading: config }) do
      User.count
    end
    ````

    *Gannon McGibbon*

*   Support default expression for MySQL.

    MySQL 8.0.13 and higher supports default value to be a function or expression.

    https://dev.mysql.com/doc/refman/8.0/en/create-table.html

    *Ryuta Kamizono*

*   Support expression indexes for MySQL.

    MySQL 8.0.13 and higher supports functional key parts that index
    expression values rather than column or column prefix values.

    https://dev.mysql.com/doc/refman/8.0/en/create-index.html

    *Ryuta Kamizono*

*   Fix collection cache key with limit and custom select to avoid ambiguous timestamp column error.

    Fixes #33056.

    *Federico Martinez*

*   Add basic API for connection switching to support multiple databases.

    1) Adds a `connects_to` method for models to connect to multiple databases. Example:

    ```
    class AnimalsModel < ApplicationRecord
      self.abstract_class = true

      connects_to database: { writing: :animals_primary, reading: :animals_replica }
    end

    class Dog < AnimalsModel
      # connected to both the animals_primary db for writing and the animals_replica for reading
    end
    ```

    2) Adds a `connected_to` block method for switching connection roles or connecting to
    a database that the model didn't connect to. Connecting to the database in this block is
    useful when you have another defined connection, for example `slow_replica` that you don't
    want to connect to by default but need in the console, or a specific code block.

    ```
    ActiveRecord::Base.connected_to(role: :reading) do
      Dog.first # finds dog from replica connected to AnimalsBase
      Book.first # doesn't have a reading connection, will raise an error
    end
    ```

    ```
    ActiveRecord::Base.connected_to(database: :slow_replica) do
      SlowReplicaModel.first # if the db config has a slow_replica configuration this will be used to do the lookup, otherwise this will throw an exception
    end
    ```

    *Eileen M. Uchitelle*

*   Enum raises on invalid definition values

    When defining a Hash enum it can be easy to use [] instead of {}. This
    commit checks that only valid definition values are provided, those can
    be a Hash, an array of Symbols or an array of Strings. Otherwise it
    raises an ArgumentError.

    Fixes #33961

    *Alberto Almagro*

*   Reloading associations now clears the Query Cache like `Persistence#reload` does.

    ```
    class Post < ActiveRecord::Base
      has_one :category
      belongs_to :author
      has_many :comments
    end

    # Each of the following will now clear the query cache.
    post.reload_category
    post.reload_author
    post.comments.reload
    ```

    *Christophe Maximin*

*   Added `index` option for `change_table` migration helpers.
    With this change you can create indexes while adding new
    columns into the existing tables.

    Example:

        change_table(:languages) do |t|
          t.string :country_code, index: true
        end

    *Mehmet Emin İNAÇ*

*   Fix `transaction` reverting for migrations.

    Before: Commands inside a `transaction` in a reverted migration ran uninverted.
    Now: This change fixes that by reverting commands inside `transaction` block.

    *fatkodima*, *David Verhasselt*

*   Raise an error instead of scanning the filesystem root when `fixture_path` is blank.

    *Gannon McGibbon*, *Max Albrecht*

*   Allow `ActiveRecord::Base.configurations=` to be set with a symbolized hash.

    *Gannon McGibbon*

*   Don't update counter cache unless the record is actually saved.

    Fixes #31493, #33113, #33117.

    *Ryuta Kamizono*

*   Deprecate `ActiveRecord::Result#to_hash` in favor of `ActiveRecord::Result#to_a`.

    *Gannon McGibbon*, *Kevin Cheng*

*   SQLite3 adapter supports expression indexes.

    ```
    create_table :users do |t|
      t.string :email
    end

    add_index :users, 'lower(email)', name: 'index_users_on_email', unique: true
    ```

    *Gray Kemmey*

*   Allow subclasses to redefine autosave callbacks for associated records.

    Fixes #33305.

    *Andrey Subbota*

*   Bump minimum MySQL version to 5.5.8.

    *Yasuo Honda*

*   Use MySQL utf8mb4 character set by default.

    `utf8mb4` character set with 4-Byte encoding supports supplementary characters including emoji.
    The previous default 3-Byte encoding character set `utf8` is not enough to support them.

    *Yasuo Honda*

*   Fix duplicated record creation when using nested attributes with `create_with`.

    *Darwin Wu*

*   Configuration item `config.filter_parameters` could also filter out
    sensitive values of database columns when call `#inspect`.
    We also added `ActiveRecord::Base::filter_attributes`/`=` in order to
    specify sensitive attributes to specific model.

    ```
    Rails.application.config.filter_parameters += [:credit_card_number, /phone/]
    Account.last.inspect # => #<Account id: 123, name: "DHH", credit_card_number: [FILTERED], telephone_number: [FILTERED] ...>
    SecureAccount.filter_attributes += [:name]
    SecureAccount.last.inspect # => #<SecureAccount id: 42, name: [FILTERED], credit_card_number: [FILTERED] ...>
    ```

    *Zhang Kang*, *Yoshiyuki Kinjo*

*   Deprecate `column_name_length`, `table_name_length`, `columns_per_table`,
    `indexes_per_table`, `columns_per_multicolumn_index`, `sql_query_length`,
    and `joins_per_query` methods in `DatabaseLimits`.

    *Ryuta Kamizono*

*   `ActiveRecord::Base.configurations` now returns an object.

    `ActiveRecord::Base.configurations` used to return a hash, but this
    is an inflexible data model. In order to improve multiple-database
    handling in Rails, we've changed this to return an object. Some methods
    are provided to make the object behave hash-like in order to ease the
    transition process. Since most applications don't manipulate the hash
    we've decided to add backwards-compatible functionality that will throw
    a deprecation warning if used, however calling `ActiveRecord::Base.configurations`
    will use the new version internally and externally.

    For example, the following `database.yml`:

    ```
    development:
      adapter: sqlite3
      database: db/development.sqlite3
    ```

    Used to become a hash:

    ```
    { "development" => { "adapter" => "sqlite3", "database" => "db/development.sqlite3" } }
    ```

    Is now converted into the following object:

    ```
    #<ActiveRecord::DatabaseConfigurations:0x00007fd1acbdf800 @configurations=[
      #<ActiveRecord::DatabaseConfigurations::HashConfig:0x00007fd1acbded10 @env_name="development",
        @spec_name="primary", @config={"adapter"=>"sqlite3", "database"=>"db/development.sqlite3"}>
      ]
    ```

    Iterating over the database configurations has also changed. Instead of
    calling hash methods on the `configurations` hash directly, a new method `configs_for` has
    been provided that allows you to select the correct configuration. `env_name`, and
    `spec_name` arguments are optional. For example these return an array of
    database config objects for the requested environment and a single database config object
    will be returned for the requested environment and specification name respectively.

    ```
    ActiveRecord::Base.configurations.configs_for(env_name: "development")
    ActiveRecord::Base.configurations.configs_for(env_name: "development", spec_name: "primary")
    ```

    *Eileen M. Uchitelle*, *Aaron Patterson*

*   Add database configuration to disable advisory locks.

    ```
    production:
      adapter: postgresql
      advisory_locks: false
    ```

    *Guo Xiang*

*   SQLite3 adapter `alter_table` method restores foreign keys.

    *Yasuo Honda*

*   Allow `:to_table` option to `invert_remove_foreign_key`.

    Example:

       remove_foreign_key :accounts, to_table: :owners

    *Nikolay Epifanov*, *Rich Chen*

*   Add environment & load_config dependency to `bin/rake db:seed` to enable
    seed load in environments without Rails and custom DB configuration

    *Tobias Bielohlawek*

*   Fix default value for mysql time types with specified precision.

    *Nikolay Kondratyev*

*   Fix `touch` option to behave consistently with `Persistence#touch` method.

    *Ryuta Kamizono*

*   Migrations raise when duplicate column definition.

    Fixes #33024.

    *Federico Martinez*

*   Bump minimum SQLite version to 3.8

    *Yasuo Honda*

*   Fix parent record should not get saved with duplicate children records.

    Fixes #32940.

    *Santosh Wadghule*

*   Fix logic on disabling commit callbacks so they are not called unexpectedly when errors occur.

    *Brian Durand*

*   Ensure `Associations::CollectionAssociation#size` and `Associations::CollectionAssociation#empty?`
    use loaded association ids if present.

    *Graham Turner*

*   Add support to preload associations of polymorphic associations when not all the records have the requested associations.

    *Dana Sherson*

*   Add `touch_all` method to `ActiveRecord::Relation`.

    Example:

        Person.where(name: "David").touch_all(time: Time.new(2020, 5, 16, 0, 0, 0))

    *fatkodima*, *duggiefresh*

*   Add `ActiveRecord::Base.base_class?` predicate.

    *Bogdan Gusiev*

*   Add custom prefix/suffix options to `ActiveRecord::Store.store_accessor`.

    *Tan Huynh*, *Yukio Mizuta*

*   Rails 6 requires Ruby 2.4.1 or newer.

    *Jeremy Daer*

*   Deprecate `update_attributes`/`!` in favor of `update`/`!`.

    *Eddie Lebow*

*   Add `ActiveRecord::Base.create_or_find_by`/`!` to deal with the SELECT/INSERT race condition in
    `ActiveRecord::Base.find_or_create_by`/`!` by leaning on unique constraints in the database.

    *DHH*

*   Add `Relation#pick` as short-hand for single-value plucks.

    *DHH*


Please check [5-2-stable](https://github.com/rails/rails/blob/5-2-stable/activerecord/CHANGELOG.md) for previous changes.
