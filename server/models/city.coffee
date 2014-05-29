http      = require "http"
async     = require "async"
americano = require "americano-cozy"

module.exports = City = americano.getModel "City",
    "name":
        "type": String
    "created":
        "type": Date,
        "default": Date


httpGet = (url, deflt, callback) ->
    result = deflt
    req = http.get url, (res) ->
        data   = ""
        chunks = []
        length = 0

        res.on "data", (chunk) ->
            chunks.push chunk
            length += chunk.length

        res.on "end", () ->
            data   = Buffer.concat chunks, length
            result = ""
            if data.length
                result = JSON.parse(data.toString("UTF-8"))
            callback(result)

    req.on "error", ->
        callback(deflt, "error")


addCityKeys = (mainKey, values, city) ->
    for key, value of values
        city[mainKey][key] = value
    city


City.baseUrl        = "http://api.openweathermap.org/data/2.5/"
City.weatherUrl     = City.baseUrl + "weather?q="
City.forecastUrl    = City.baseUrl + "forecast/?q="
City.dayForecastUrl = City.baseUrl + "forecast/daily?cnt=5&q="

City.fullCity = (city, mainCallback) ->
    weatherUrl     = City.weatherUrl + city.name
    forecastUrl    = City.forecastUrl + city.name
    dayForecastUrl = City.dayForecastUrl + city.name

    fullCity =
        "id": city.id
        "name": city.name
        "weather": {},
        "hours": {},
        "days": {}

    async.series([
        ((callback) ->
            httpGet weatherUrl, null, (weather, err) =>
                if not err
                    fullCity = addCityKeys "weather", weather, fullCity
                callback()),
        ((callback) ->
            httpGet forecastUrl, null, (forecast, err) =>
                if not err
                    fullCity = addCityKeys "hours", forecast, fullCity
                callback()),
        ((callback) ->
            httpGet dayForecastUrl, null, (forecast, err) =>
                if not err
                    fullCity = addCityKeys "days", forecast, fullCity
                callback(null, fullCity))
    ], (err, results) ->
        mainCallback(null, fullCity))

City.fullCities = (cities, callback) ->
    async.map cities, @fullCity, (err, results) ->
        callback(err, results)

City.all = (callback) ->
    @request "all", (err, cities) =>
        if err
            callback.call(@, err, [])
        else
            @fullCities(cities, callback)
