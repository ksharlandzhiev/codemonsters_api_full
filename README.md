# README

### Introduction

This application is a simple payment gateway implementing a JSON API via the Rails 5 API mode. Usually merchants with online businesses integrate with payment gateways in order to offer electronic payments to their customers. The API allows you to trigger Sale and Void transactions and receive the transaction's status and unique identifier.

### Supported transaction types:

##### Sale
A Sale transaction allows the merchant to bill directly the customer's credit card.

##### Void
A Sale transaction can be reversed with a Void transaction and this way it will not show up on the customer's credit card statement.
Real world Void transactions can be triggered only on the same day the corresponding Sale transaction took place.

## Setup

### Ubuntu set up

* Update ubuntu
```
sudo apt-get update
```

* Install required dependencies
```
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev
```

* install [RVM](https://rvm.io/rvm/install)
[Ruby](http://ruby-doc.org/)
[Rails](http://guides.rubyonrails.org/)

```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 2.2.2
rvm use 2.2.2 --default
ruby -v

gem install bundler
```

* Configure Git **optional**
```
git config --global color.ui true
git config --global user.name "YOUR NAME"
git config --global user.email "YOUR@EMAIL.com"
ssh-keygen -t rsa -b 4096 -C "YOUR@EMAIL.com"

cat ~/.ssh/id_rsa.pub

ssh -T git@github.com
```

* Clone the repository and issue the following commands:
```
$ bundle install
$ bundle exec rake db:create:all
$ bundle exec rake db:schema:load
$ bundle exec rails s -p 3001
```

### Minutes per module

1. PaymentTransactionsController
   1. expalin routes.rb
   2. strong params
   3. make 'create' action

2. PaymentTransaction model
   1.  factory! method
   2.  process!

3. Gateway model
   1. process method
   2. process_transaction method

### Authentication

To interact with the gateway API, you need to provide login credentials using standard HTTP Basic Authentication. Credentials can be set in your config file.

### Root API endpoint

`http://localhost:3001`

### Create a Sale transaction

`POST /payment_transactions`

###### Parameters

name|description
----|----
card_number|Card Number
cvv|Three digit number printed on the back of the card
expiration_date|Card's expiration date
amount|Amount to be charged
usage|Reason for the payment
transaction_type|sale
card_holder|Card holder's name
email|Customer's email address
address|Customer's address


###### Example request

```json
$ curl http://localhost:3001/payment_transactions \
    -H "Content-Type: application/json;charset=UTF-8" \
    -H "Authorization: Basic cGFuZGFoYXB2YTprYWNoYW1haw==" \
    -d '{
    "payment_transaction": {
      "card_number": "4200000000000000",
      "cvv": "123",
      "expiration_date": "06/2019",
      "amount": "500",
      "usage": "Coffeemaker",
      "transaction_type": "sale",
      "card_holder": "Panda Panda",
      "email": "panda@example.com",
      "address": "Panda Street, China"
    }
}'
```

###### Example success response

```json
HTTP/1.1 200 OK
Content-Type:application/json;charset=UTF-8

{
  "unique_id": "0e08644635ccb520c2eeb54f33865660",
  "status": "approved",
  "usage": "Coffeemaker",
  "amount": 500,
  "transaction_time": "2016-11-11T15:32:01.368Z",
  "message": "Your transaction has been approved."
}
```

### Create a Void transaction

`POST /payment_transactions`

###### Parameters

name|description
----|----
reference_id|Sale transaction `unique_id`
transaction_type|void

###### Example request

```json
$ curl http://localhost:3001/payment_transactions \
    -H "Content-Type: application/json;charset=UTF-8" \
    -H "Authorization: Basic cGFuZGFoYXB2YTprYWNoYW1haw==" \
    -d '{
    "payment_transaction": {
      "reference_id": "0e08644635ccb520c2eeb54f33865660",
      "transaction_type": "void"
    }
}'

```

```json
HTTP/1.1 200 OK
Content-Type:application/json;charset=UTF-8

{
  "unique_id": "7e59f0116b74d62e3980ee0231b02dc4",
  "status": "approved",
  "usage": "Coffeemaker",
  "amount": 500,
  "transaction_time": "2016-11-11T15:25:38.817Z",
  "message": "Your transaction has been voided successfully"
}
```


### Errors

##### HTTP Status Codes

Status Code|Description
----|----
200|OK
401|Access denied
422|Unprocessable entity

###### Example Sale error response

```json
HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8

{
  "unique_id": "2f256d59ce3472459704dc43040f0788",
  "status": "declined",
  "usage": "Coffeemaker",
  "amount": 500,
  "transaction_time": "2016-11-11T15:32:34.913Z",
  "message": "Your transaction has been declined!"
}
```

###### Example Void error response

```json
HTTP/1.1 422 Unprocessable entity
Content-Type: application/json;charset=UTF-8

{
  "reference_id": ["Invalid reference transaction!"]
}
```


