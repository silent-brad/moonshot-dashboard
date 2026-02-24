local api = {}

function api.fetch_current(api_key, city, country, units)
    if not api_key or api_key == "" then
        return {
            temp = 72,
            feels_like = 70,
            humidity = 45,
            condition = "clear",
            description = "Clear sky",
            city = city or "New York",
            units = units or "imperial",
        }
    end

    local url = string.format(
        "https://api.openweathermap.org/data/2.5/weather?q=%s,%s&appid=%s&units=%s",
        city, country, api_key, units
    )

    local response, err = http.get(url)
    if not response then
        return nil, err
    end

    local data = json.decode(response.body)
    if not data or not data.main then
        return nil, "Invalid API response"
    end

    return {
        temp = math.floor(data.main.temp),
        feels_like = math.floor(data.main.feels_like),
        humidity = data.main.humidity,
        condition = api.map_condition(data.weather and data.weather[1] and data.weather[1].main),
        description = data.weather and data.weather[1] and data.weather[1].description or "",
        city = data.name or city,
        units = units,
    }
end

function api.map_condition(condition)
    local mapping = {
        Clear = "clear",
        Clouds = "cloudy",
        Rain = "rain",
        Drizzle = "rain",
        Thunderstorm = "storm",
        Snow = "snow",
        Mist = "fog",
        Fog = "fog",
        Haze = "fog",
    }
    return mapping[condition] or "clear"
end

return api
