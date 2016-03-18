# Expense

An expense managing application to make life more easier and free. This is the backend API server written on top of the [Ruby on Rails](http://rubyonrails.org) framework.

**Table of Contents**

- [Development Setup](#development-setup)
- [Testing](#testing)
- [Deploy](#deploy)
- [API](#api)
  - [Conventions](#conventions)
    - [HTTP Methouds](#http-methouds)
    - [Value Unit](#value-unit)
  - [Authentication Related APIs](#authentication-related-apis)
    - [User Registration](#user-registration)
    - [User Authentication (OAuth)](#user-authentication)
  - [General APIs](#general-apis)
    - [Account Management](#account-management)
    - [Transaction Management](#transaction-management)
    - [Transaction Category Set Management](#transaction-category-set-management)
- [Architecture](#architecture)
  - [Environment Variables](#environment-variables)
  - [Domain Model ERD Diagram](#domain-model-erd-diagram)
  - [The Settings Model](#the-settings-model)
  - [Objects](#objects-value-objects-parameter-objects-etc)
    - [Transaction Category Set](#transactioncategoryset-transaction-categorizing)
  - [Service Modules](#service-modules)
  - [Backing Services](#backing-services)
  - [Synchronizers](#synchronizers)
    - [Collector](#collector)
    - [Parser](#parser)
    - [Organizer](#organizer)
  - [Specs](#specs)
    - [Module Specs](#module-specs)
    - [Request Specs](#request-specs)
    - [Feature Specs](#feature-specs)


## Development Setup

Just run:

```bash
$ bin/setup
```

Configure the application by editing the environment variables in `.env`. After that's done, you can start the development server by running `bin/server`, enter the console by `bin/console`, or run the tests by `bin/rspec`.

> Note: After updating (i.e. pulling a new version from the remote repo), be sure to run `bin/update` before you do anything.


## Testing

Run `bin/rspec spec` to execute the RSpec test suite.

Integrations test that require communications with real-world web services are skipped by default. Set the `INTEGRATION_TEST` environment variable to run them: `INTEGRATION_TEST=true bin/rspec spec`.


## Deploy

This application is designed under [The Twelve Factor App](http://12factor.net/) pattern, making its deployment and operations on cloud platforms easy.


## API

Most APIs provided by this app are RESTful JSON APIs, and OAuth 2.0 is used for authentication.

Note that although most examples are using URL query parameters to pass data, form-data or raw body with JSON can also be used. Also, the OAuth access token can be passed using HTTP `Authorization` header (`Authorization: Bearer <access_token>`) instead of the `access_token` query parameter.

### Conventions

#### HTTP Methouds

##### Using `PUT` for Resource Creation

Since this is an mobile oriented application, one considerations on API design is to make requests retryable (we assume that the internet is unstable). The traditional `POST` method is not retryable since it will create n duplicated resource after retrying n times.

By using the `PUT` method (its definition is "replace or create"), we can make creating resource retryable by:

  1. Generate the unique ID of that resource on the client side.
  2. Send the request `PUT /resources/<generated_uid>` to create the resource.

If the client thinks the request has failed, it can just retry step 2 without the worry of creating duplicated resources on the server side. Because the definition of `PUT` request is "replace or create", if that resource is already created successfully, resending the same request will simply "replace" that resource with the same data - making no changes to the final result.

For this reason, `POST` methods are not provided for some APIs.

##### Using `PATCH` for Updating Resource

Since the definition of `PUT` request is "replace or create", it may be inconvenient for updating only a subset of attributes: all old attributes should be send within the request, otherwise the missing attributes will be cleared (because the whole resource has been replaced with the provided data).

So, the recommended method for updating resourse is using `PATCH` requests. Only the attributes specified in the request will be updated, while others remain unchanged.

For this reason, `PUT` methods are not provided for some APIs.

#### Value Unit

All money values like `amount` or `balance` are integers represented in 1,000/1 degrees, irrelevant to currency. That is, the programmatic money value `1234567` should be displayed as `$ 1,234.567`.

### Authentication Related APIs

#### User Registration

New users can be registered using their email and password ([spec](https://github.com/Neson/Expense/blob/master/spec/requests/users_spec.rb)).

```http
POST /users?
     user[email]=<email>&
     user[password]=<password>&
     user[password_confirmation]=<password_confirmation>
```

Sample response:

```json
{
  "user": {
    "email": "someone@somewhere.com"
  },
  "status": "confirmation_pending"
}
```

A confirmation email will be sent after the new registration. After new users clicked the account activation link in the confirmation email, they will be able to login.

> TODO: Reset password API.

#### User Authentication

All authentications are done by [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749). All of the rest APIs will need a valid access token to access. The Resource Owner Password Credentials Grant Flow is supported to obtain an access token:

##### Resource Owner Password Credentials Grant Flow

This grant flow uses the user's account credentials to grant access and get an access token ([spec](https://github.com/Neson/Expense/blob/master/spec/requests/oauth/token_spec.rb)). The API endpoint is `POST /oauth/token`, and two types of credentials are supported:

###### Using Email and Password

Pass the user's email as the username and the password with the request like this:

```http
POST /oauth/token?
     grant_type=password&
     username=<email>&
     password=<password>
```

Sample response:

```json
{
  "access_token": "xxxxxxx",
  "token_type": "bearer",
  "expires_in": 7200,
  "refresh_token": "xxxxxxxxxx",
  "scope": "default",
  "created_at": 00000000
}
```

> The `grant_type` parameter is fixed to value `password` to use this grant flow.

After 20+ unsuccessful credentials attempts, the user's account will be locked and cannot be logged in within a maximum time of 3 hours.

###### Using an Facebook Access Token

To achieve "loggin in with Facebook", a vaild Facebook access token is also available to use as credential. Just use the fixed value `facebook:access_token` as the `username`, and pass in the Facebook access token as password:

```http
POST /oauth/token?
     grant_type=password&
     username=facebook:access_token&
     password=<facebook_access_token>
```

If the corresponding user does not exists, a new user will with blank password be created and link to that Facebook account automatically. The automatically created user will not be able to login using password unless they use the reset password API to set their password.

Or if an old user is using Facebook login without linking his/her Facebook account before, his/her account will be found out by matching email and link to that Facebook account.

> Note that for security reasons, only the Facebook access tokens that belongs to the same Facebook app setted for this application can be used as credentials. Facebook access tokens that are created for other Facebook apps will be rejected - even if they belong to the same user.

##### Using The Refresh Token

The refresh token is used for obtending a new access token after the current one has (or is going to) expired ([spec](https://github.com/Neson/Expense/blob/master/spec/requests/oauth/token_spec.rb)). A sample request is:

```http
POST /oauth/token?
     grant_type=refresh_token&
     refresh_token=xxxxxxx
```

the sample response:

```json
{
  "access_token": "xxxxxxx",
  "token_type": "bearer",
  "expires_in": 7200,
  "refresh_token": "xxxxxxxxxx",
  "scope": "default",
  "created_at": 00000000
}
```

### General APIs

#### Account Management

All the transactions (the log of expense or income) are filed under accounts. A default cash account with the name "default" and type "cash" will be created with the new user ([spec](https://github.com/Neson/Expense/blob/master/spec/models/user_spec.rb)) and set as the default account ([spec](https://github.com/Neson/Expense/blob/master/spec/models/user_spec.rb)). Default accounts cannot be deleted ([spec](https://github.com/Neson/Expense/blob/master/spec/models/account_spec.rb)). Operations for managing the user's accounts are listed below:

##### Getting The List of Accounts

```http
GET /me/accounts
```

Sample response:

```json
accounts: [
  {
    "uid": "9aa5d2b6-a3c9-4d0e-891e-b43f40d2546d",
    "name": "default",
    "type": "cash",
    "currency": "TWD",
    "balance": 8000000
  },
  {
    "uid": "4a58cb98-59ac-4401-9ff0-2d0887e31250",
    "name": "悠遊卡",
    "type": "cash",
    "currency": "TWD",
    "balance": 5000000
  }
]
```

> Note that the `balance` attribute is represented in 1,000/1 degrees.

##### Creating an Account

```http
PUT /me/accounts/<generated_unique_id>
Content-Type: application/json

{
  "account": {
    "name": <the_name_of_the_account>,
    "type": "cash",
    "currency": "TWD",
    "balance": <the_initial_balance>
  }
}
```

##### Updating Info of an Account

```http
PATCH /me/accounts/<account_uid>
Content-Type: application/json

{
  "account": <updated_attributes_and_values>
}
```

##### Deleting an Account

```http
DELETE /me/accounts/<account_uid>
```

#### Transaction Management

The log of an expense or income is a transaction. Transactions are filed under accounts, and the account balance will be auto updated after a transaction has been created, updated or deleted ([spec](https://github.com/Neson/Expense/blob/master/spec/models/transaction_spec.rb)). Transactions are categorized into categories and can add tags onto, which provide ways for filter and analyzing. Operations for managing transactions are listed below:

##### Getting All Transactions

```http
GET /me/transactions
```

This API is [Paginatable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Paginatable), [Sortable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Sortable) and [Filterable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Filterable).

Sample response:

```json
{
  "transactions": [
    {
      "account_uid": "15-149f840d-dda4-4b30-81ce-90aebc4950f3",
      "uid": "f37e0e61-6601-4934-9f9f-5d50b7f80563",
      "amount": 700000,
      "description": "Breakfast at Starbucks",
      "category_code": "breakfast",
      "note": null,
      "datetime": "2016-02-27T08:32:38.088Z",
      "latitude": null,
      "longitude": null,
      "ignore_in_statistics": false,
      "created_at": "2016-02-27T06:32:38.092Z",
      "updated_at": "2016-02-27T06:32:38.092Z"
    },
    ...
  ],
  "pagination": {
    "items_count": 820,
    "pages_count": 33,
    "links": {
      "next": "http://localhost:3000/me/transactions?page=2",
      "last": "http://localhost:3000/me/transactions?page=33"
    }
  }
}
```

> Note that the `amount` attribute is represented in 1,000/1 degrees.

##### Getting All Transactions Under An Account

```http
GET /me/accounts/<account_uid>/transactions
```

This API is [Paginatable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Paginatable), [Sortable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Sortable) and [Filterable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Filterable).

The response format is same as `GET /me/transactions`.

##### Creating A Transaction

```http
PUT /me/accounts/<account_uid>/transactions/<generated_unique_id>
Content-Type: application/json

{
  "transaction": <transaction_attrs>
}
```

##### Updating A Transaction

```http
PATCH /me/accounts/<account_uid>/transactions/<transaction_uid>
Content-Type: application/json

{
  "transaction": <transaction_attrs>
}
```

##### Deleting A Transaction

```http
DELETE /me/accounts/<account_uid>/transactions/<transaction_uid>
```

#### Transaction Category Set Management

Each transaction can be categorize into one category by their `category_code`. This API manages the categories defined by the user.

The attributes of a category are `code`, `name`, `priority` and `hidden`. The `code` is a unique identifier of the category. The `priority` decides the order of that category to be show on UI, while it should be hidden on the UI with `hidden` set to `true`. Every category are filed under a parent-category, parent-categories also has the attributes `code`, `name`, `priority` and `hidden`.

This app will define a default set of categories. All user's category settings will inherit this set. Users are free to create, update or delete any custom categories. But predefined categories, or categories having at least one transaction can not be deleted, they can just set to be `hide` ([spec](https://github.com/Neson/Expense/blob/master/spec/services/transaction_category_service_spec.rb)).

Updating the category set on the backend server side can let users access their category set everywhere. The user defined category set will also be used for auto-categorizing.

##### Retrieving The Transaction Category Set

```http
GET /me/transaction_category_set
```

Sample response:

```json
{
  "transaction_categories": {
    "transaction_parent_category_one_code": {
      "priority": 1,
      "name": "Transaction Parent Category One",
      "hidden": false,
      "children": {
        "transaction_category_one_code": {
          "priority": 1,
          "name": "Transaction Category One",
          "hidden": false
        },
        "hidden_transaction_category_code": {
          "priority": 2,
          "name": "Hidden Transaction Category",
          "hidden": true
        }
      }
    },
    "transaction_parent_category_two_code": {
      "priority": 2,
      "name": "Transaction Parent Category Two",
      "hidden": false,
      "children": {
        "transaction_category_two_code": {
          "priority": 1,
          "name": "Transaction Category Two",
          "hidden": false
        },

        ...
      }
    },

    ...
  }
}
```

##### Updating The Transaction Category Set

To update the category set, just send a `PUT` request to `/me/transaction_category_set` with the whole updated data in the request body. The request body format is same as the returned data of `GET /me/transaction_category_set`. To delete a category, just ignore it in the request. To rename or change the `hide` status of a category, just update the object with the same `code`. To create a new category, generate a `code` for that category, and add it to the object with the `code` as the key.

```http
PUT /me/transaction_category_set
```

Sample request:

```http
PUT /me/transaction_category_set
Content-Type: application/json

{
  "transaction_categories": {
    "transaction_parent_category_one_code": {
      "priority": 1000,
      "name": "Move This To Bottom!",
      "hidden": false,
      "children": {
        "transaction_category_one_code": {
          "priority": 1,
          "name": "Hide This!",
          "hidden": true
        },
        "hidden_transaction_category_code": {
          "priority": 2,
          "name": "Show This!",
          "hidden": false
        }
      }
    },
    "transaction_parent_category_two_code": {
      "priority": 1,
      "name": "Move This To Top!",
      "hidden": false,
      "children": {
        "transaction_category_two_code": {
          "priority": 1,
          "name": "Rename This!",
          "hidden": false
        },

        ...
      }
    },

    ...
  }
}
```

##### Get Transaction Categorization Suggestion For Some Words

```http
GET /me/accounts/<account_id>/transaction_categorization_suggestion?words=<some_words>
```

Sample response:

```json
{
  "category_code": "drinks"
}
```


## Architecture

This app is built on top of [Ruby on Rails](http://rubyonrails.org), with [Devise](https://github.com/plataformatec/devise), [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper/), [Jbuilder](https://github.com/rails/jbuilder) and many others. Tests are done by [RSpec](http://rspec.info/). The architecture of this app is briefly explained in the sections below:

### Environment Variables

By following [The Twelve Factor App](http://12factor.net/) pattern, this application should be [configurable via environment variables](http://12factor.net/config).

Available environment variable, "ENVs", should be listed in `.env.sample` with their sample values.

### Domain Model ERD Diagram

![Domain Model ERD Diagram](https://raw.githubusercontent.com/Neson/Expense/master/erd.png?token=ADm_71Ifa7vq1QTmzrWclqSeHpCZUG-kks5W7aHqwA%3D%3D)

> Note: This diagram is generated with the command `bin/erd`.

### The Settings Model

The `Settings` model is a way to store key-value settings in the database. This functionality is provided by [rails-settings-cached](https://github.com/Neson/rails-settings-cached).

Note that making direct changes to `Settings` is not recommended. While doing this, the values aren't validated before saving, this may breake the app. A better way is to call the *set settings* method defined in other class or modules, and let them manage the settings for you. (For example, use `TransactionCategorySet.hash = { ... }` to set the default category set instead of calling `Settings.transaction_category_set = ...`.)

### Objects: Value Objects, Parameter Objects, etc.

A variant kinds of pure objects are used in this app: [Value Objects](http://refactoring.com/catalog/replaceDataValueWithObject.html), [Parameter Objects](http://refactoring.com/catalog/introduceParameterObject.html) and so on. These objects lives under `app/objects`.

#### `TransactionCategorySet`: Transaction Categorizing

The `TransactionCategorySet` is used to manage transaction categories, both for this app and each user.

Class methods `.hash` and `.hash=` can be used to get and set the category set defined by this app.

Instances of `TransactionCategorySet` should be initialized with a `User`. An of instances `TransactionCategorySet` represents actions to the specified user. Instance methods `#hash` and `#hash=` are used to get and set the custom category set for a user.

Each instances of `TransactionCategorySet` provides a method `#categorize`. `#categorize` is a auto-classifier that returns a conjecturing category code, based on a string of words, and optional datetime, latitude and longitude. `TransactionCategorySet#categorize` for each user are not the same, since users have their own `transaction_category_set` and manual categorizing log that will be learned. The conjecture is based on these conditions too.

```ruby
user = User.find(1)
tcs = TransactionCategorySet.new(user)  # or user.transaction_category_set

datetime = Time.new(2000, 1, 1, 23, 0, 0, 0)  # => 2000/1/1 23:00:00 at UTC
latitude = 23.5; longitude = 121  # Taiwan, UTC+8

category_code = tcs.categorize("Roasted Chicken Sandwich", datetime: datetime, latitude: latitude, longitude: longitude)
# => "breakfast"
```

_▴ Demo of using `TransactionCategorySet#categorize`._

The functionality of `#categorize` is based on records in the model `TransactionCategorizationCase`. `TransactionCategorizationCase` has attribute `words`, `category_code` and a optional `user_id`. For each example case, `words` is the sample words of an transcaion that should be categorize into `category_code`. `TransactionCategorizationCase`s without an `user_id` are shared by all users, while those with a specified `user_id` only effects that user.

New `TransactionCategorizationCase`s are automatically created with an `user_id` while the user uses `PUT /me/accounts/<account_id>/transactions/<transaction_id>` or `PATCH /me/accounts/<account_id>/transactions/<transaction_id>` to update a transaction with a specified `category_code`. Exploring `TransactionCategorizationCase` and clear the `user_id` for those are a general case is a way to improve the correct rate of the auto-transaction-categorizing feature for all users.

### Service Modules

Service Modules (or "Service Objects") encapsulate operations that are used widely over the application. These operations often meets one or more of the following criteria:

- Complex.
- Interacts with an external service.
- Interacts with multiple models.
- Not a core concern of the interacted model.

These modules lives under `app/services`.

### Backing Services

Communication with backing services, such as database, file storage, outbound email service, Facebook connection, Apple Push Notification Service and GCM, are all wrapped in external gems or service objects to provide united API, logic arrangement and easy testing. That is to say, there are hardly any direct `RestClient.get ...` or other TCP, HTTP connections be fired in models, controllers or jobs. They're at least wrapped into service-oriented service object or gems, or further more, wrapped as functionality-oriented libs for a more high-level API.

These type of service objects written in this app will provide a `mock_mode` module attr. While it is set to `true`, no real connections to those backing services will be established, and mock data will be used for return value. This is normally used for testing. And the mock data written in those modules can also act as documentation.

### Synchronizers

Synchronizers ("Syncers") does the auto expense logging. It syncs from real-word expense record _(such as credit card bills, banking websites, receipt emails, etc.)_ to the transaction record in this app. They lives under `app/synchronizers` and do their jobs mostly in scheduled background workers.

Synchronizers are service-oriented. A synchronizer class maintains transaction records coming from a specific bank, store, or other service. Some synchronizer manages accounts _(such as credit card bill syncer or bank log syncer)_, while some doesn't _(such as receipt email syncer)_. Synchronizers that doesn't manage accounts should be used with a existing account.

All Synchronizers inherits the class `Synchronizer`, a `ActiveRecord` based model locates at `app/models/synchronizer.rb`. They use the Rails STI mechanism to share the same database table.

Each synchronizer has their `CODE`, `REGION_CODE`, `NAME`, `DESCRIPTION`, `PASSCODE_INFO` defined:

- [`Symbol`] `CODE`: An unique identifier of the syncer.
- [`Symbol`] `REGION_CODE`: The region code. This can be `nil`.
- [`String`] `NAME`: The display name.
- [`String`] `DESCRIPTION`: A description of the syncer.
- [`Hash`] `PASSCODE_INFO`: A hash that states the usage of passcode for this syncer. An example is:

  ```ruby
  PASSCODE_INFO = {
    1 => {
      name: 'Account Name',
      description: 'Your account name for Xxx Bank',
      required: true,
      format: /\d{4}-\d{8}/
    },
    2 => {
      name: 'Password',
      description: 'Your data inquire password for the account',
      required: true
    },
    3 => {
      name: 'Verification Code',
      description: 'The verification code, if you\'ve set it',
      required: false
    }
  }.freeze
  ```

- [`Hash`] `SCHEDULE_INFO`: A hash that states the running schedule of this syncer, it must contains exactly three `Array`s of `String`s with keys `normal`, `high_frequency` and `low_frequency`, specifying the times of day to run. All time zones are in UTC. The minute must be a multiple of 10. An example is:

  ```ruby
  SCHEDULE_INFO = {
    normal: {
      %w(16:00 22:00 04:00 10:00),
      description: 'Four times a day'
    },
    high_frequency: {
      %w(**:00),
      description: 'Every hour'
    },
    low_frequency: {
      %w(16:00 04:00),
      description: 'Twice a day'
    }
  }.freeze
  ```

All enabled syncers will run on the specified times of a day. The schedule (Synchronizer#schedule) is defaulted to `normal`, while users can set to use `high_frequency` or `low_frequency`. Running is triggered by the `clock` process (see `Procfile` under the project root directory, and `lib/clock.rb`).

The implementation of each synchronizer is constructed by three parts: `Collector`, `Parser` and `Organizer`. The `Synchronizer` class defines these three abstract sub-class, while each inherited children should implement them:

#### Collector

The collector collects raw data and saves them into the `Synchronizer::CollectedPage` model.

A `Collector` class should define to public methods: `run` and `recieve`.

The `run` method starts the collector to collect data. To control the deepness of collecting data _(for example, we want to collect [the webpages updated today] hourly, [webpages that may change recently] daily and [the whole website] monthly)_, it must take an optional key argument: `level`, this argument can be passed in symbols `:normal`, `:light` or `:complete`, to determine that this collecting should be normal, light or complete.

The `recieve` method will be called if data is sent in proactively (for example, by billing email). It takes an argument `data` and a key argument `type`. The `data` will be the page body and `type` as the data type.

#### Parser

The parser parses new data in the `Synchronizer::CollectedPage` model, and saves the parsed data into the `Synchronizer::ParsedData` model.

The `run` method starts the parser to parse data. This method must take an optional key argument: `level`, this argument can be passed in as symbol `:normal` or `:complete`. While `:normal` will parse just unparse pages, `:complete` is expected to parse all saved pages.

#### Organizer

The organizer reads data from `Synchronizer::ParsedData` and manages (create or update) transactions and accounts.

The `run` method starts the organizer to organize data. This method must take an optional key argument: `level`, this argument can be passed in as symbol `:normal` or `:complete`. While `:normal` will organize just unorganized records, `:complete` is expected to organize all parsed data again.

### Specs

The specs of this app are written in RSpec tests placing in the project's `./spec` directory. Three main categories of specs are included: `modules`, `requests` and `features`.

#### Module Specs

This is the module level unit test. Covering models, services and more, they are filed under the corresponding `models`, `services` directory under the project's `./spec` directory, same as the structure in the project's `./app` directory.

#### Request Specs

Request specs specified all the surface accessible APIs of this app. They're organized by their API path in the `requests` directory.

#### Feature Specs

Non-API features, such as browsable web pages of this app, are specified in feature specs placed in in the `features` directory.
