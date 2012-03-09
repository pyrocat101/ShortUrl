# URL Shortener

This is a simple URL shortener written in CoffeeScript and Jade template language. It uses Redis for data storage.

# How to use

* Install dependencies

    `npm install`

* Check the configuration

    By default, URL shortener app assumes [redis-server](http://redis.io/) at ```localhost:6379```. However, it can be easily changed to other hosts or ports in `app.coffee`.

    Besides, the service is running at port `3000`. You should change it to others to suit your needs.

* Run the service

    The server-side is fully written in [CoffeeScript](http://coffeescript.org/). Run the server from coffee-script command-line:
    
    `coffee app`

    Compile scripts is another alternative:

    ```
    coffee -c *.coffee
    node app
    ```

# API

The URL shortener also provides an API to retrieve short URLs for abitrary long URLs. See the index page on dev server for further description.

