# Expense [![](https://img.shields.io/travis/expenture/Expense.svg)](https://travis-ci.org/expenture/Expense)

An expense managing application to make life more easier and free. This is the API server written on top of the [Ruby on Rails](http://rubyonrails.org) framework.

**Table of Contents**

- [Development Setup](#development-setup)
- [Testing](#testing)
- [Deploy](#deploy)
  - [WebHook And Callback Endpoints](#webhook-and-callback-endpoints)
- [API Guide](#api-guide)
  - [Conventions](#conventions)
    - [HTTP Methods](#http-methods)
    - [JSON Schema](#json-schema)
    - [Errors And The Error Object](#errors-and-the-error-object)
    - [Value Unit](#value-unit)
  - [Authentication Related APIs](#authentication-related-apis)
    - [User Registration](#user-registration)
    - [User Authentication (OAuth)](#user-authentication)
  - [General APIs](#general-apis)
    - [Account Management](#account-management)
    - [Transaction Management](#transaction-management)
    - [Transaction Category Set Management](#transaction-category-set-management)
    - [Synchronizer Management](#synchronizer-management)
    - [Account Identifier Management](#account-identifier-management)
- [Application Architecture](#application-architecture)
  - [Environment Variables](#environment-variables)
  - [Domain Model ERD Diagram](#domain-model-erd-diagram)
  - [The Settings Model](#the-settings-model)
  - [Objects](#objects-value-objects-parameter-objects-etc)
    - [Transaction Category Set](#transactioncategoryset-transaction-categorizing)
  - [Service Modules](#service-modules)
  - [Backing Services](#backing-services)
  - [Account Organizing Service](#account-organizing-service)
  - [Synchronizers](#synchronizers)
    - [Collector](#collector)
    - [Parser](#parser)
    - [Organizer](#organizer)
  - [Specs](#specs)
    - [Module Specs](#module-specs)
    - [Request Specs](#request-specs)
    - [Feature Specs](#feature-specs)
- [Badges](#badges)


## Development Setup

Just run:

```bash
$ bin/setup
```

Then configure the application by editing the environment variables in `.env`. After that's done, you can start the development server by running `bin/server`, enter the console by `bin/console`, or run the tests by `bin/test`.

> Note: After updating (i.e. pulling a new version from the remote repo), be sure to run `bin/update` before you do anything.


## Testing

Run `bin/test` to execute the test suite.

Integration tests that requires communication with real-world web services are skipped by default. Set the `INTEGRATION_TEST` environment variable to `true` to run them: `INTEGRATION_TEST=true bin/test`.


## Deploy

This application is designed with [The Twelve Factor App](http://12factor.net/) pattern, making its deployment and operations on cloud platforms easy. You can deploy this app to heroku with one click: [![Deploy](https://neson.github.io/GitHub-Badges/deploy_to_heroku_xs.svg)](https://heroku.com/deploy).

The major system dependencies to run this app are: `ruby`, `bundler`, `imagemagick` and `tesseract`. A `phantomjs` executable for `linux` and `darwin` is included in this code base.

Primary configurations of this app are controlled by environment variables (ENVs). A sample `.env` file listing primary ENVs is located at `.env.sample`. This app relies on several backing services (with their connection configured using ENVs), Some of them might need to send data to this app by using WebHook or callbacks, more details about this are described in the [WebHook And Callback Endpoints](#webhook-and-callback-endpoints) section below.

There are three process types for this app: web servers (`web`), background job workers (`worker`) and the clock `clock`. See the `Procfile` to learn about how to start the processes in a general case.

### WebHook And Callback Endpoints

There're a few API endpoints for other service to send data into this app:

#### 3rd Party Sign In OAuth Callbacks

- Facebook: `/users/auth/facebook/callback`

#### Inbound Email Receiving for Syncers

- [Mailgun (forwarding URL for routes)](https://documentation.mailgun.com/quickstart-receiving.html#inbound-routes-and-parsing): `/webhook_endpoints/syncer_receiving/mailgun`


## API Guide

Most APIs provided by this app are RESTful JSON APIs, and OAuth 2.0 is used for authentication.

> Note: **URL query parameters**, **form-data** or **raw body with JSON** are all available ways for passing parameters for a request. Also, the OAuth access token can be hand over using HTTP the `Authorization` header (`Authorization: Bearer <access_token>`) instead of the `access_token` query parameter. Examples in this documentation might use any of the above ways for clarity, but you are free to choice which method to use while making API requests.

### Conventions

#### HTTP Methods

##### Using `PUT` for Resource Creation

Since this is a mobile oriented application, one consider on API design is to make requests retryable (we assume that the internet is unstable). The traditional `POST` method is not retryable since it will create `n` duplicated resource after retrying `n` times.

By using the `PUT` method (its definition is "replace or create"), we can make creating resource retryable by:

  1. Generate a unique ID (uid) of that resource on the client side.
  2. Send the request `PUT /resources/{uid}` to create that resource.

If the client thinks the request has failed, it can just retry step 2 without the worry of creating duplicated resources on the server side. Because the definition of `PUT` request is "replace or create", if that resource is already created successfully, resending the same request will simply "replace" that resource with the same data - making no changes to the final result.

For this reason, `POST` methods are not provided for some APIs.

##### Using `PATCH` for Updating Resource

Since the definition of `PUT` request is "replace or create", it may be inconvenient for updating only a subset of attributes: all old attributes should be send within the request, otherwise the missing attributes will be cleared (because the whole resource has been replaced with the provided data).

So, the recommended method for updating resourse is using `PATCH` requests. Only the attributes specified in the request will be updated, while others remain unchanged.

For this reason, `PUT` methods are not provided for some APIs.

#### JSON Schema

The returned resource will be wrapped in a object, with their type as the key:

```json
{
  "account": {
    ...
  }
}
```

```json
{
  "accounts": [
    { ... },
    { ... },
    { ... }
  ]
}
```

#### Errors And The Error Object

APIs provided by this app uses conventional HTTP status codes to indicate errors:

- `200` OK - Everything is fine.
- `201` Created - The request success with the creation of a new resource.
- `202` Accepted - The request has been accepted for processing, but the processing has not been completed.
- `400` Bad Request - Your request has invalid arguments or is malformed.
- `401` Unauthorized - Your request is not (or has failed to be) authenticated.
- `403` Forbidden - Your request is authenticated, but has Insufficient permissions for this request.
- `405` Method Not Allowed - The HTTP verb of the request is incorrect.
- `404` Not Found - The requested API endpoint or the resource does not exist.
- `429` Too Many Requests - You've exceeded the API request rate limit.
- `500` Internal Server Error - Something is wrong on the server side.
- `504` Gateway Timeout - Something has timed out on the server side.

If the response is considered to have an error, a `error` object will be returned in the JSON:

```json
{
  "error": {
    "status": 400,
    "code": "bad_attributes",
    "message": "Account: Name can't be blank"
  },
  "account": {
    "uid": "a991c2e2-2999-a136-3f05-db20c3c455d2",
    "type": "cash",
    "name": null,
    ...
    "errors": {
      "name": [
        "can't be blank"
      ]
    }
  }
}
```

The `status` of the error object is the HTTP code. The `code` is an error code and the `message` is a friendly error message. Common `code`s are:

- `bad_attributes` - The request attributes is invalid.

#### Value Unit

All money values like `amount` or `balance` are integers represented in 1,000/1 degrees, irrelevant to currency. That is, the programmatic money value `1234567` should be displayed as `$ 1,234.567`.

### Authentication Related APIs

APIs in this section is used for user registration or authentication (i.e. register and sign in).

#### User Registration

New users can be registered using their email and a password ([spec](https://github.com/expenture/Expense/blob/master/spec/requests/users_spec.rb)).

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
    "email": "someone@somewhere.com",
    ...
  },
  "status": "confirmation_pending"
}
```

A confirmation email will be sent after the new registration. After new users clicked the account activation link in the confirmation email, they will be able to sign in.

##### Reset Password

Users can reset their password if forgotten, or desired to sign in with password while their account created with Facebook Sign In. To do so, just specify the email of the account to sign in:

```http
POST /users/password?
     user[email]=<email>
```

An email with the password reset link will be sent to that email after the request.

#### User Authentication

This app implements [OAuth 2.0](http://oauth.net/2/) for authentication. Most of the APIs will need a valid access token to access.

##### Resource Owner Password Credentials Grant Flow

This grant flow uses the user's account credentials to grant access and get an access token ([spec](https://github.com/expenture/Expense/blob/master/spec/requests/oauth/token_spec.rb)). The API endpoint is `POST /oauth/token`.

> If you made 20+ unsuccessful attempts, the user's account will be locked and cannot be logged in within a maximum time of 3 hours.

To grant for an access token, you need to pass `client_id` and `client_secret` with the user's email as the username and the password with the request like this:

```http
POST /oauth/token?
     grant_type=password&
     client_id={client_id}&
     client_secret={client_secret}&
     username={email}&
     password={password}
```

Sample response:

```json
{
  "access_token": "2fd434f0f4835c5f810256ed04c117b33b90a35c3c6da0b6a5b773fce98b4ff6",
  "token_type": "bearer",
  "expires_in": 7200,
  "refresh_token": "4f9cb068d2b2c5f86bae4d21ea17949a6a0aa9f8634c9226d14419ad178e6b9e",
  "scope": "default",
  "created_at": 1458313774
}
```

> The `grant_type` parameter is fixed to value `password` to use this grant flow.

The `client_id` and `client_secret` are credentials to verify the client (namely, the OAuth Application). These credentials are necessary, because all access tokens should be issued with an client, so that users can manage their authorized clients, view access logs and revoke access later.

> You can create an OAuth Application in the console (`$ bin/console`) like this: `OAuthApplication.create(name: 'My New App')`.

If you want to create an OAuth Application on the fly (normally for mobile/desktop app clients, a OAuth Application as a device), pass the params `client_uid`, `client_type` and `client_name` instead of `client_id` and `client_secret` like this:

```http
POST /oauth/token?
     grant_type=password&
     client_uid="14f93c7c-676e-465f-b1e2-360a901a04fa"
     client_type="ios_device"&
     client_name="User's iPhone 5S"&
     username="user@example.com"&
     password="abcd1234"
```

> `client_uid` is a pre-generated uid to prevent creating duplicated OAuth Applications.

###### Using An Facebook Access Token

To let users sign in with Facebook, a vaild Facebook access token is also available to use as credential. Just use the fixed value `facebook:access_token` as the `username`, and pass in the Facebook access token as password:

```http
POST /oauth/token?
     grant_type=password&
     client_id={client_id}&
     client_secret={client_secret}&
     username=facebook:access_token&
     password={facebook_access_token}
```

If the corresponding user does not exists, a new user will with blank password be created and link to that Facebook account automatically. The automatically created user will not be able to sign in using password unless they use the reset password API to set their password.

Or if an old user is using Facebook sign in without linking his/her Facebook account before, his/her account will be found out by a matching email and link to that Facebook account.

> Note that for security reasons, only the Facebook access tokens that belongs to the same Facebook app configured for this application can be used as credentials. Facebook access tokens that are created for other Facebook apps will be rejected - even if they belong to the same user.

##### Using The Refresh Token

The refresh token is used for obtending a new access token after the current one has (or is going to) expired ([spec](https://github.com/expenture/Expense/blob/master/spec/requests/oauth/token_spec.rb)). A sample request is:

```http
POST /oauth/token?
     grant_type=refresh_token&
     refresh_token=4f9cb068d2b2c5f86bae4d21ea17949a6a0aa9f8634c9226d14419ad178e6b9e
```

the response will be like:

```json
{
  "access_token": "359eb6e59d78c35b3933f4266ca1680fc733fba5783f5780a191ce4c078c880d",
  "token_type": "bearer",
  "expires_in": 7200,
  "refresh_token": "9b3124588e96673563da7ebce13b13c27defdc379b426bb94611c7cd27b1ac1e",
  "scope": "default",
  "created_at": 1458313916
}
```

### General APIs

Accessing APIs in this section requires a valid access token, otherwise a `401 Unauthorized` error will be returned.

#### Account Management

Accounts represent places to store money. It can be a wallet, a bank account, a debit card or a credit card. Accounts have a list of transactions.

A default cash account with the name "default" and type "cash" will be created with the new user ([spec](https://github.com/expenture/Expense/blob/master/spec/models/user_spec.rb)) and set as the default account ([spec](https://github.com/expenture/Expense/blob/master/spec/models/user_spec.rb)). Default accounts cannot be deleted ([spec](https://github.com/expenture/Expense/blob/master/spec/models/account_spec.rb)).

There are two different types of accounts: **normal accounts** and **<strong id="api-guide-syncing-accounts">syncing accounts</strong>**. Normal accounts are those that transactions are managed by the user manually, while syncing accounts has all the transactions synced with a service (e.g. a bank) automatically. Normal accounts are created by the user, and syncing accounts are created and managed by syncers.

> Note: More details about syncers are described under the [Synchronizer Management](#synchronizer-management) section later.

Operations for managing the user's accounts are listed below:

##### Listing Accessible Accounts

Returns a list of accounts that is accessible by the current authorised user.

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
    "balance": 8000000,
    "default": true,
    "syncing": false
  },
  {
    "uid": "4a58cb98-59ac-4401-9ff0-2d0887e31250",
    "name": "悠遊卡",
    "type": "cash",
    "currency": "TWD",
    "balance": 5000000,
    "default": false,
    "syncing": true
  }
]
```

> Note that the `balance` attribute is represented in 1,000/1 degrees ([ref](#value-unit)).

##### Creating An Account

Creates a new account for current authorised user.

```http
PUT /me/accounts/{generated_unique_id}
Content-Type: application/json

{
  "account": {
    "name": "My Wallet",
    "type": "cash",
    "currency": "TWD",
    "balance": 1000000
  }
}
```

##### Updating An Account

Updates attributes of a specified account that is owned by the current authorised user.

```http
PATCH /me/accounts/{account_uid}
Content-Type: application/json

{
  "account": {
    "name": "My Old Wallet",
    "type": "cash",
    "currency": "TWD",
    "balance": 0
  }
}
```

##### Deleting An Account

Deletes a specified account that is owned by the current authorised user.

```http
DELETE /me/accounts/{account_uid}
```

> Note: The default account and [syncing accounts](#api-guide-syncing-accounts) cannot be deleted.

##### Cleaning An Account

Cleans the transactions (find possible matching between not-on-record transactions and on-record transactions to link them together, resolving the duplication) on an account. Normally users don't need to run this manually.

```http
POST /me/accounts/{account_uid}/_clean
```

##### Merging Two Accounts

Merges transactions from a source account to a target account. A use case is to merge from a manual managed account to a syncing account, then the user can have old records on their new syncing account, and delete the old manual account. Transactions will be auto merged by coping transactions from the source account to the target account as not-on-record transactions, and cleaning the target account.

```http
POST /me/accounts/{account_uid}/_merge?source_account_uid={source_account_uid}
```

> Note that by merging accounts, any account identifier pointed to the source (old) account will be updated to point to the target (new) account automatically for the user. More info about account identifiers are described in the [Account Identifier Management](#account-identifier-management) section later.

#### Transaction Management

Transactions are records of money movements into or out of an account. A transaction with negative amount represent expenses, while those with positive amount represent incomes.

Transactions are listed under accounts. The account balance will update automatically after a transaction has been created, updated or deleted ([spec](https://github.com/expenture/Expense/blob/master/spec/models/transaction_spec.rb)).

Transactions can be categorized by the `category_code` attribute. More details about how categorizing works is explained in the [Transaction Category Set Management](#transaction-category-set-management) section later.

##### Listing All Transactions

Returns a list of all transactions that is accessible by the current authorised user.

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

> Note that the `amount` attribute is represented in 1,000/1 degrees ([ref](#value-unit)).

##### Listing Transactions On An Account

Returns a list of transactions on a specified account that is accessible by the current authorised user.

```http
GET /me/accounts/{account_uid}/transactions
```

This API is [Paginatable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Paginatable), [Sortable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Sortable) and [Filterable](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Filterable).

The response format is same as `GET /me/transactions`.

##### Creating A Transaction

Creats a new transaction on a account that is accessible by the current authorised user.

```http
PUT /me/accounts/{account_uid}/transactions/{uid}
Content-Type: application/json

{
  "transaction": <transaction_attrs>
}
```

If you're creating a transaction on [syncing accounts](#api-guide-syncing-accounts), the transaction you manually created will be a **<strong id="api-guide-not-on-record-transaction">not-on-record transaction</strong>** (having its `on_record` be `false`), meaning that this transaction is not on the official record, but is pre-created for convenience. If the syncer creates that actual transaction record on the next syncing, it will find the not-on-record transaction that you manually created, copy its attributes to the new and actual transaction, and set the not-on-record one to be `ignore_in_statistics`. This enables you to pre-log some transactions immediately, needless to wait for the syncer done the next syncing to edit them.

> Note: More details about syncers are described under the [Synchronizer Management](#synchronizer-management) section later.

##### Updating A Transaction

Updates a transaction on a account that is accessible by the current authorised user.

```http
PATCH /me/accounts/{account_uid}/transactions/{uid}
Content-Type: application/json

{
  "transaction": <transaction_attrs>
}
```

##### Deleting A Transaction

Deletes a transaction from a account that is accessible by the current authorised user.

```http
DELETE /me/accounts/{account_uid}/transactions/{uid}
```

> Note: User can not delete on-record transactions from a syncing account (i.e. accounts that are managed by syncers). More details about syncers are described under the [Synchronizer Management](#synchronizer-management) section later.

##### Separating A Transaction

Sometimes you'll want to take apart a big transaction record into multiple transactions for better representation and statistics. For example, as you buy things on _Apple_'s _App Store_ or _iTunes_, _Apple_ always charges your credit card for a whole bunch of stuff in one single bill, making the transaction record for different type of things - productivity apps, entertainment games, songs, books, etc. - all mixed together. Another example is when you checked out for a wide-range of things in a hyper market with a single credit card swipe. Although that transaction must appear as a single one on your credit card bill, you can create several **virtual transaction**s to separate it.

The API used to create virtual transactions for separating a transaction is same as the one for [creating a transaction](#creating-a-transaction). The difference is to specify a `separate_transaction_uid` for the new transaction:

```http
PUT /me/accounts/{account_uid}/transactions/{uid}
Content-Type: application/json

{
  "transaction": {
    "separate_transaction_uid": "523c2b1b-82b4-406a-b7b6-4a5e79aedd45",
    ...
  }
}
```

As you specify the `separate_transaction_uid` for a transaction, then it will be considered as a **virtual transaction**. The `separate_transaction_uid` is the `uid` of the transaction that will be separated. Creating virtual transactions will not effect the balance of an account. You can create as many virtual transactions as you need to separate a transaction.

If you create virtual transactions to separate a transaction, the separated transaction will be marked to be `ignore_in_statistics` automatically, so that your statistics will express the real information. The actual separated transaction still remain exists, and can be used in some situations, such as accounting reconciliation.

#### Transaction Category Set Management

Each transaction can be categorize into one category by their `category_code`. This API is used for managing the set of available categories that is customized by the user. The category set can be used to display transaction categories in human-friendly wording, or showing a category selecting UI. It is also used for this app for transaction auto categorizing features.

The attributes of a category are `code`, `name`, `priority` and `hidden`. The `code` is a unique identifier of the category. The `priority` decides the order of that category to be show on the UI, while it should be hidden while `hidden` set to `true`.

Every category should be listed under a parent-category, parent-categories also has the attributes `code`, `name`, `priority` and `hidden`.

The app defines a default set of categories, and all user's category set will inherit this app-defined set. Users are free to create, update or delete any custom categories. But app-defined categories, or categories having at least one transaction can not be deleted, they can just set to be `hidden` ([spec](https://github.com/expenture/Expense/blob/master/spec/services/transaction_category_service_spec.rb)).

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

To update the category set, just send a `PUT` request to `/me/transaction_category_set` with the whole updated data in the request body. The request body format is same as the returned data of `GET /me/transaction_category_set`.

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

This app supports auto transaction categorizing. It will learn by every time the user sets the `category_code` for a transaction.

This API returns a suggested `category_code` for some given words using the auto transaction categorizing feature.

```http
GET /me/accounts/{account_id}/transaction_categorization_suggestion?words={some_words}
```

Sample response:

```json
{
  "category_code": "drinks"
}
```

#### Synchronizer Management

Synchronizers ("Syncers") syncs data from your bank accounts, card accounts or bills to transactions in this app automatically (i.e. does the auto expense logging for you).

Synchronizers has different types, different types of syncers syncs data from different services. Some types of synchronizer manages accounts _(such as credit card syncer or bank account syncer)_, while some doesn't _(such as receipt email syncer, they conjectures the account that you paid form by the receipt, and create transactions on that existing account)_.

> Note: To make email-receiving syncers to work, you'll need to configure inbound email receiving. See the [Inbound Email Receiving for Syncers](#inbound-email-receiving-for-syncers) section for further info.

##### Listing Available Syncer Types

Returns the available syncer types and their details in this app.

```http
GET /synchronizer_types
```

##### Listing User's Syncers

Returns a list of syncers that the current authorised user has added.

```http
GET /me/synchronizers
```

##### Adding A Syncer

Adds a syncer for the current authorised user.

```http
PUT /me/synchronizers/{uid}
Content-Type: application/json

{
  "synchronizer": {
    "type": "apple_receipt",
    "name": "My Syncer",
    "passcode_1": null,
    "passcode_2": null,
    ...
  }
}
```

##### Updating A Syncer

Updates attributes for a syncer that is owned by the current authorised user.

```http
PATCH /me/synchronizers/{uid}
Content-Type: application/json

{
  "synchronizer": {
    "name": "My Syncer",
    "enabled": true,
    "schedule": "normal",
    "passcode_1": null,
    "passcode_2": null,
    ...
  }
}
```

> TODO: Destroy syncer API.

##### Manually Run A Syncer

Calls a syncer perform synchronization immediately.

```http
POST /me/synchronizers/{uid}/_perform_sync
```

This request will return `202` if the syncer has be successfully prepared for running, or return `400` if there's an error occured while starting the syncer.

> TODO: Stop syncing API.

#### Account Identifier Management

The Account Identifier is a way for this app to identify accounts. Say, a syncer receives an receipt that states the credit card `****-****-****-1234` has been charged, but the syncer will have no idea which account `****-****-****-1234` actually is. The syncer will then create a new `AccountIdentifier` with `type`: `credit_card` and `identifier`: `1234`, then skip that data for the user to identify an account later. After the user assigns an account for that `AccountIdentifier`, the syncer can then create that transaction in the account on its next run.

There is no way for users to create `AccountIdentifier`s manually. `AccountIdentifier`s will only be created when unidentified account appears while the app runs.

##### Listing User's Account Identifiers

```http
GET /me/account_identifiers
```

##### Updating A Account Identifier

```http
PATCH /me/account_identifiers/{id}
Content-Type: application/json

{
  "account_identifier": {
    "account_uid": <an_account_uid>
  }
}
```


## Application Architecture

This app is built on top of [Ruby on Rails](http://rubyonrails.org), with [Devise](https://github.com/plataformatec/devise), [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper/), [Jbuilder](https://github.com/rails/jbuilder) and many others. Tests are done by [RSpec](http://rspec.info/). The architecture of this app is briefly explained in the sections below:

### Environment Variables

By following [The Twelve Factor App](http://12factor.net/) pattern, this application should be [configurable via environment variables](http://12factor.net/config).

Available environment variable, "ENVs", should be listed in `.env.sample` with their sample values.

### Domain Model ERD Diagram

![Domain Model ERD Diagram](https://raw.githubusercontent.com/expenture/Expense/master/erd.png)

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

New `TransactionCategorizationCase`s are automatically created with an `user_id` while the user uses `PUT /me/accounts/{account_id}/transactions/{transaction_id}` or `PATCH /me/accounts/{account_id}/transactions/{transaction_id}` to update a transaction with a specified `category_code`. Exploring `TransactionCategorizationCase` and clear the `user_id` for those are a general case is a way to improve the correct rate of the auto-transaction-categorizing feature for all users.

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

#### Account Organizing Service

`AccountOrganizingService` is a service module that provides two methods for organizing accounts: `clean` and `merge`.

The `clean` method takes an `Account` instance as the argument, it finds duplication between on-record transactions not-on-record transactions (by the same amount and datetime differences within 25 hours), then links the not-on-record transaction to its on-record transaction, i.e. cleans that account. This method can be also used to clean syncing accounts by syncers.

The `merge` method is used if the user wants to merge transactions from a old account (source account) to a new one (target account). It will copy all the old transactions from the source account and place them as not-on-record transactions on the target one, after that, the `clean` method is used to clean the target account.

### Synchronizers

Synchronizers ("Syncers") does the auto expense logging. It syncs from real-word expense record _(such as credit card bills, banking websites, receipt emails, etc.)_ to the transaction record in this app. They lives under `app/synchronizers` and do their jobs mostly in scheduled background workers.

Synchronizers are service-oriented. A synchronizer class maintains transaction records coming from a specific bank, store, or other service. Some synchronizer manages accounts _(such as credit card bill syncer or bank log syncer)_, while some doesn't _(such as receipt email syncer)_.

All Synchronizers inherits the class `Synchronizer`, a `ActiveRecord` based model locates at `app/models/synchronizer.rb`. They use the Rails STI mechanism to share the same database table.

Each synchronizer has their `CODE`, `REGION_CODE`, `NAME`, `DESCRIPTION`, `PASSCODE_INFO` defined:

- [`Symbol`] `CODE`: (Required) An unique identifier of the syncer.
- [`Symbol`] `REGION_CODE`: The region code.
- [`Symbol`] `TYPE`: The syncer type.
- [`Array`] `COLLECT_METHODS`: (Required) An array of symbols, specifying the supported data collecting methods of this syncer. Available symbols are: `:run` and `:email`.
- [`String`] `NAME`: (Required) The display name.
- [`String`] `DESCRIPTION`: (Required) A description of the syncer.
- [`String`] `INTRODUCTION`: (Required) A longer introduction about the syncer.
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

- [`Hash`] `SCHEDULE_INFO`: (Required) A hash that states the running schedule of this syncer, it must contains exactly three `Array`s of `String`s with keys `normal`, `high_frequency` and `low_frequency`, specifying the times of day to run. All time zones are in UTC. The minute must be a multiple of 10. An example is:

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

- [`String`] `EMAIL_ENDPOINT_INTRODUCTION`: An introduction about the email endpoint of the synchronizer

All enabled syncers will run on the specified times of a day. The schedule (Synchronizer#schedule) is defaulted to `normal`, while users can set to use `high_frequency` or `low_frequency`. Running is triggered by the `clock` process (see `Procfile` under the project root directory, and `lib/clock.rb`).

The implementation of each synchronizer is constructed by three parts: `Collector`, `Parser` and `Organizer`. The `Synchronizer` class defines these three abstract sub-class, while each inherited children should implement them:

#### Collector

The collector collects raw data and saves them into the `Synchronizer::CollectedPage` model.

A `Collector` class should define to public methods: `run` and `recieve`.

The `run` method starts the collector to collect data. To control the deepness of collecting data _(for example, we want to collect [the webpages updated today] hourly, [webpages that may change recently] daily and [the whole website] monthly)_.

The `recieve` method will be called if data is sent in proactively (for example, by billing email). It takes an argument `data` and a key argument `type`. The `data` will be the page body and `type` as the data type.

#### Parser

The parser parses new data in the `Synchronizer::CollectedPage` model, and saves the parsed data into the `Synchronizer::ParsedData` model.

The `run` method starts the parser to parse data.

Note that the `ParsedData` model should be one-to-one correspond to the actual data. Unlike `CollectedPage`, duplication is not recommended to be allowed for `ParsedData`. This makes `ParsedData` re-organizable, and `ParsedData` must be re-organizable in case of the user wants to change some syncer related configurations.

#### Organizer

The organizer reads data from `Synchronizer::ParsedData` and manages (create or update) transactions and accounts.

The `run` method starts the organizer to organize data.

### Specs

The specs of this app are written in RSpec tests placing in the project's `./spec` directory. Three main categories of specs are included: `modules`, `requests` and `features`.

#### Module Specs

This is the module level unit test. Covering models, services and more, they are filed under the corresponding `models`, `objects`, `services` and `synchronizers` directory under the project's `./spec` directory, same as the structure in the project's `./app` directory.

#### Request Specs

Request specs specified all the surface accessible APIs of this app. They're organized by their API path in the `requests` directory. We aim for 100% test coverage on all opened request APIs.

#### Feature Specs

Non-API features, such as browsable web pages of this app, are specified in feature specs placed in in the `features` directory.


## Badges

- [![Travis](https://img.shields.io/travis/expenture/Expense.svg)](https://travis-ci.org/expenture/Expense)
- [![Coveralls](https://img.shields.io/coveralls/expenture/Expense.svg)](https://coveralls.io/github/expenture/Expense)
- [![Code Climate](https://img.shields.io/codeclimate/github/expenture/Expense.svg)](https://codeclimate.com/github/expenture/Expense)
- [![Codacy](https://img.shields.io/codacy/ef578c9c49b44dd8baee65460542fc9f.svg)](https://www.codacy.com/app/me_71/Expense)
- [![Gemnasium](https://img.shields.io/gemnasium/expenture/Expense.svg)](https://gemnasium.com/github.com/expenture/Expense)
