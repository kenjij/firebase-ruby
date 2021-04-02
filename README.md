# firebase-ruby

[![Gem Version](https://badge.fury.io/rb/firebase-ruby.svg)](http://badge.fury.io/rb/firebase-ruby) [![Code Climate](https://codeclimate.com/github/kenjij/firebase-ruby/badges/gpa.svg)](https://codeclimate.com/github/kenjij/firebase-ruby) [![security](https://hakiri.io/github/kenjij/firebase-ruby/master.svg)](https://hakiri.io/github/kenjij/firebase-ruby/master)

A pure Ruby library for [Firebase Realtime Database](https://firebase.google.com/products/database/) [REST API](https://firebase.google.com/docs/reference/rest/database/) which has only one external dependency: [jwt](http://jwt.github.io/ruby-jwt/).  `firebase-ruby` uses Ruby's built-in Net::HTTP for all HTTP access.

## Getting Started

## Firebase Realtime Database

Firebase SDK makes it easy to work with Realtime Database. However, on the server-side you you'll likely have to work with the REST API directly, and on top of this you will need to deal with OAuth, which can get complicated in a server environment.

To use firebase-ruby, you'll need a [Service Account and its Private Key](https://firebase.google.com/docs/database/rest/auth#generate_an_access_token). This needs to be in JSON format. Now, you have two ways to use it.

_See [Access Token](#oauth-20-access-token) for more details on that._

## Usage 1) CLI: fbrb

This gem has a built-in command `fbrb` as an example use and for quick testing.

```sh
fbrb -k privatekey.json /
```

This will download the entire database in JSON format. By using the private key JSON file provided via Firebase console when creating a service account, necessary information such as project ID, URL, credentials are automatically applied.

## Usage 2) In Your App

```ruby
require 'firebase-ruby'

# If you want to enable debug logging
Firebase.logger = Logger.new(STDOUT)
Firebase.logger.level = Logger::DEBUG

db = Firebase::Database.new()
db.set_auth_with_key(path: path_to_key_file)
# or alternatively supply the JSON as string
db.set_auth_with_key(json: json_string)

db.get('/users/jack/name')
#{
#  "first": "Jack",
#  "last": "Sparrow"
#}

db.put('/users/jack/name', {first: "Jack", last: "Sparrow"})
#{
#  "first": "Jack",
#  "last": "Sparrow"
#}

db.post('/message_list', {user_id: "jack", text: "Ahoy!"})
#{
#  "name": "-INOQPH-aV_psbk3ZXEX"
#}

db.patch('/users/jack/name', {last: "Jones"})
#{
#  "last": "Jones"
#}

db.delete('/users/jack/name/last')
```

## AWS Lambda Layers

Trying to use it in a Lambda function but lost figuring out how to install gems? See [firebase-lambda-layer](https://github.com/kenjij/firebase-lambda-layer).

## OAuth 2.0 Access Token

Using the given credentials, `firebase-ruby` will automatically retrieve the [access token](https://firebase.google.com/docs/reference/rest/database/user-auth) from Google's server. The token is valid for 1 hour but a new token will be fetched right before it expires.

`firebase-ruby` keeps the Google OAuth 2.0 process a black box. But for more details, see the document on Google Developers which the process is based on: [Using OAuth 2.0 for Server to Server Applications](https://developers.google.com/identity/protocols/oauth2/service-account).
