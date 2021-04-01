# firebase-ruby

[![Gem Version](https://badge.fury.io/rb/firebase-ruby.svg)](http://badge.fury.io/rb/firebase-ruby) [![Code Climate](https://codeclimate.com/github/kenjij/firebase-ruby/badges/gpa.svg)](https://codeclimate.com/github/kenjij/firebase-ruby) [![security](https://hakiri.io/github/kenjij/firebase-ruby/master.svg)](https://hakiri.io/github/kenjij/firebase-ruby/master)

A pure Ruby library for [Firebase Realtime Database](https://firebase.google.com/products/database/) [REST API](https://firebase.google.com/docs/reference/rest/database/) which has only one external dependancy: [jwt](http://jwt.github.io/ruby-jwt/).  `firebase-ruby` uses Ruby's built-in Net::HTTP for all HTTP access.

## CLI: fbrb

This gem has a built-in command `fbrb` as an example use and for quick testing.

```sh
fbrb -k privatekey.json /
```

This will download the entire database in JSON format. By using the private key JSON file provided via Firebase console when creating a service account, necessary information such as project ID, URL, credentials are automatically applied.

## Using In An App

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

## OAuth 2.0 Access Token

Using the given credentials, `firebase-ruby` will automatically retrieve the [access token](https://firebase.google.com/docs/reference/rest/database/user-auth) from Google's server. The token is valid for 1 hour but a new token will be fetched right before it expires.

`firebase-ruby` keeps the Google OAuth 2.0 process a black box. But for more details, see the document on Google Developers which the process is based on: [Using OAuth 2.0 for Server to Server Applications](https://developers.google.com/identity/protocols/oauth2/service-account).
