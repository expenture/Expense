# Expense

An expense managing application to make life more easier and free. This is the backend API server written on top of the [Ruby on Rails](http://rubyonrails.org) framework.

**Table of Contents**

- [Development Setup](#development-setup)
- [Deploy](#deploy)
- [API](#api)
  - [User Registration](#user-registration)
  - [User Authentication (OAuth)](#user-authentication)
    - [Resource Owner Password Credentials Grant Flow](#resource-owner-password-credentials-grant-flow)
      - [Using Email and Password](#using-email-and-password)
      - [Using an Facebook Access Token](#using-an-facebook-access-token)
    - [Using The Refresh Token](#using-the-refresh-token)
- [Architecture](#architecture)
  - [Specs](#specs)
    - [Module Specs](#module-specs)
    - [Request Specs](#request-specs)
    - [Feature Specs](#feature-specs)
  - [Backing Services](#backing-services)


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

### User Registration

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

### User Authentication

All authentications are done by [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749). All of the rest APIs will need a valid access token to access. The Resource Owner Password Credentials Grant Flow is supported to obtain an access token:

#### Resource Owner Password Credentials Grant Flow

This grant flow uses the user's account credentials to grant access and get an access token ([spec](https://github.com/Neson/Expense/blob/master/spec/requests/oauth/token_spec.rb)). The API endpoint is `POST /oauth/token`, and two types of credentials are supported:

##### Using Email and Password

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

##### Using an Facebook Access Token

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

#### Using The Refresh Token

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

## Architecture

The architecture of this app is briefly explained in the sections below:

### Specs

The specs of this app are written in RSpec tests placing in the project's `./spec` directory. Three main categories of specs are included: `modules`, `requests` and `features`.

#### Module Specs

This is the module level unit test. Covering models, services and more, they are filed under the corresponding `models`, `services` directory under the project's `./spec` directory, same as the structure in the project's `./app` directory.

#### Request Specs

Request specs specified all the surface accessible APIs of this app. They're organized by their API path in the `requests` directory.

#### Feature Specs

Non-API features, such as browsable web pages of this app, are specified in feature specs placed in in the `features` directory.

### Backing Services

Communication with backing services, such as database, file storage, outbound email service, Facebook connection, Apple Push Notification Service and GCM, are all wrapped in external gems or service objects to provide united API, logic arrangement and easy testing. That is to say, there are hardly any direct `RestClient.get ...` or other TCP, HTTP connections be fired in models, controllers or jobs. They're at least wrapped into service-oriented service object or gems, or further more, wrapped as functionality-oriented libs for a more high-level API.

These type of service objects written in this app will provide a `mock_mode` module attr. While it is set to `true`, no real connections to those backing services will be established, and mock data will be used for return value. This is normally used for testing. And the mock data written in those modules can also act as documentation.
