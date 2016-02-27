# Expense

An expense managing application to make life more easier and free. This is the backend API server written on top of the [Ruby on Rails](http://rubyonrails.org) framework.

**Table of Contents**

- [Development Setup](#development-setup)
- [Deploy](#deploy)
- [API](#api)
  - [Conventions](#conventions)
    - [HTTP Methouds](#http-methouds)
    - [Value Unit](#value-unit)
  - [Authentication Related APIs](#authentication-related-apis)
    - [User Registration](#user-registration)
    - [User Authentication (OAuth)](#user-authentication)
      - [Resource Owner Password Credentials Grant Flow](#resource-owner-password-credentials-grant-flow)
      - [Using The Refresh Token](#using-the-refresh-token)
  - [General APIs](#general-apis)
    - [Account Management](#account-management)
    - [Transaction Management](#transaction-management)
- [Architecture](#architecture)
  - [Domain Model ERD Diagram](#domain-model-erd-diagram)
  - [Backing Services](#backing-services)
  - [Specs](#specs)
    - [Module Specs](#module-specs)
    - [Request Specs](#request-specs)
    - [Feature Specs](#feature-specs)


## Development Setup

Just run:

```bash
$ bin/setup
```

Configure the application by editing the environment variables in `.env`. After that's done, you can start the development server by running `bin/server`.


## Deploy

This application is designed under The [Twelve-Factor](http://12factor.net/) pattern, making its deployment and operations on cloud platforms easy.


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
      "date": "2016-02-27T08:32:38.088Z",
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

## Architecture

This app is built on top of [Ruby on Rails](http://rubyonrails.org), with [Devise](https://github.com/plataformatec/devise), [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper/), [Jbuilder](https://github.com/rails/jbuilder) and many others. Tests are done by [RSpec](http://rspec.info/). The architecture of this app is briefly explained in the sections below:

### Domain Model ERD Diagram

![](https://raw.githubusercontent.com/Neson/Expense/master/erd.png?token=ADm_7_rGOdlefEHT8smFsow3krbEZpGlks5W2EjswA%3D%3D)

> Note: This diagram is generated with the command `bin/erd`.

### Backing Services

Communication with backing services, such as database, file storage, outbound email service, Facebook connection, Apple Push Notification Service and GCM, are all wrapped in external gems or service objects to provide united API, logic arrangement and easy testing. That is to say, there are hardly any direct `RestClient.get ...` or other TCP, HTTP connections be fired in models, controllers or jobs. They're at least wrapped into service-oriented service object or gems, or further more, wrapped as functionality-oriented libs for a more high-level API.

These type of service objects written in this app will provide a `mock_mode` module attr. While it is set to `true`, no real connections to those backing services will be established, and mock data will be used for return value. This is normally used for testing. And the mock data written in those modules can also act as documentation.

### Specs

The specs of this app are written in RSpec tests placing in the project's `./spec` directory. Three main categories of specs are included: `modules`, `requests` and `features`.

#### Module Specs

This is the module level unit test. Covering models, services and more, they are filed under the corresponding `models`, `services` directory under the project's `./spec` directory, same as the structure in the project's `./app` directory.

#### Request Specs

Request specs specified all the surface accessible APIs of this app. They're organized by their API path in the `requests` directory.

#### Feature Specs

Non-API features, such as browsable web pages of this app, are specified in feature specs placed in in the `features` directory.
