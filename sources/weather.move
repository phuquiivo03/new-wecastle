module wecastle::weather{
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::dynamic_object_field as dof;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::transfer::{Self};
    use sui::tx_context::{Self, TxContext};


    public struct AdminCap has key, store { id: UID }

    public struct WEATHER has drop {}

    // Define a struct for the weather oracle
    public struct WeatherOracle has key {
        id: UID,
        address: address,
        name: String,
        description: String,
    }


     public struct CityWeatherOracle has key, store {
        id: UID,
        geoname_id: u32, 
        name: String, 
        country: String, 
        latitude: u32, 
        longitude: u32, 
        temp: u32, 
        visibility: u16, 
        wind_speed: u16,
        wind_deg: String, 
        clouds: u8, 
        is_rain: bool,
        rain_fall: String
    }

    public struct WeatherNFT has key, store {
        id: UID,
        geoname_id: u32, 
        name: String, 
        country: String, 
        latitude: u32, 
        longitude: u32, 
        temp: u32, 
        visibility: u16, 
        wind_speed: u16,
        wind_deg: String, 
        clouds: u8, 
        is_rain: bool,
        rain_fall: String
    }

    fun init(otw: WEATHER, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx); // Claim ownership of the one-time witness and keep it

        let cap = AdminCap { id: object::new(ctx) }; // Create a new admin capability object
        transfer::share_object(WeatherOracle {
            id: object::new(ctx),
            address: tx_context::sender(ctx),
            name: string::utf8(b"Weminal"),
            description: string::utf8(b"A weather oracle for posting weather updates (temperature, pressure, humidity, visibility, wind metrics and cloud state) for major cities around the world. Currently the data is fetched from https://openweathermap.org. SuiMeteo provides the best available information, but it does not guarantee its accuracy, completeness, reliability, suitability, or availability. Use it at your own risk and discretion."),
        });
        transfer::public_transfer(cap, @0x8d9f68271c525e6a35d75bc7afb552db1bf2f44bb65e860b356e08187cb9fa3d);
    }


    public fun add_city(
        _: &AdminCap, // The admin capability
        oracle: &mut WeatherOracle, // A mutable reference to the oracle object
        geoname_id: u32, 
        name: String, 
        country: String, 
        latitude: u32, 
        longitude: u32, 
        ctx: &mut TxContext // A mutable reference to the transaction context
    ) {
        dof::add(&mut oracle.id, geoname_id, // Add a new dynamic object field to the oracle object with the geoname ID as the key and a new city weather oracle object as the value.
            CityWeatherOracle {
                id: object::new(ctx),
                geoname_id,
                name,
                country,
                latitude,
                longitude,
                temp: 0, 
                visibility: 0, 
                wind_speed: 0,
                wind_deg: string::utf8(b"East"), 
                clouds: 0, 
                is_rain: false,
                rain_fall: string::utf8(b"None")
            }
        );
    }

     public fun remove_city(_: &AdminCap, oracle: &mut WeatherOracle, geoname_id: u32) {
        let CityWeatherOracle { 
            id,
            geoname_id: _,
            name: _,
            country: _,
            latitude: _,
            longitude: _,
            temp: _,
            visibility: _,
            wind_speed: _,
            wind_deg: _,
            clouds: _,
            is_rain: _,
            rain_fall: _
        } = dof::remove(&mut oracle.id, geoname_id);
        object::delete(id);
    }

    public fun update(
        _: &AdminCap,
        oracle: &mut WeatherOracle,
        geoname_id: u32,
        temp: u32, 
        visibility: u16, 
        wind_speed: u16,
        wind_deg: String, 
        clouds: u8, 
        is_rain: bool,
        rain_fall: String
    ) {
        let city_weather_oracle_mut = dof::borrow_mut<u32, CityWeatherOracle>(&mut oracle.id, geoname_id); // Borrow a mutable reference to the city weather oracle object with the geoname ID as the key
        city_weather_oracle_mut.temp = temp;
        city_weather_oracle_mut.visibility = visibility;
        city_weather_oracle_mut.wind_speed = wind_speed;
        city_weather_oracle_mut.wind_deg = wind_deg;
        city_weather_oracle_mut.clouds = clouds;
        city_weather_oracle_mut.is_rain = is_rain;
        city_weather_oracle_mut.rain_fall = rain_fall;
    }

    public fun mint(
        oracle: &WeatherOracle, 
        geoname_id: u32, 
        ctx: &mut TxContext
    ): WeatherNFT {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&oracle.id, geoname_id); // Borrow a reference to the city weather oracle object with the geoname ID as the key.
        WeatherNFT {
            id: object::new(ctx),
            geoname_id: city_weather_oracle.geoname_id,
            name: city_weather_oracle.name,
            country: city_weather_oracle.country,
            latitude: city_weather_oracle.latitude,
            longitude: city_weather_oracle.longitude,
            temp: city_weather_oracle.temp,
            visibility: city_weather_oracle.visibility,
            wind_speed: city_weather_oracle.wind_speed,
            wind_deg: city_weather_oracle.wind_deg,
            clouds: city_weather_oracle.clouds,
            is_rain: city_weather_oracle.is_rain,
            rain_fall: city_weather_oracle.rain_fall
        }
    }

    public fun geoname_id(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.geoname_id }
    public fun name(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.name }
    public fun country(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.country }
    public fun latitude(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.latitude }
    public fun longitude(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.longitude }
    public fun temp(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.temp }
    public fun visibility(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.visibility }
    public fun wind_speed(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.wind_speed }
    public fun wind_deg(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.wind_deg }
    public fun clouds(city_weather_oracle: &CityWeatherOracle): u8 { city_weather_oracle.clouds }
    public fun is_rain(city_weather_oracle: &CityWeatherOracle): bool { city_weather_oracle.is_rain }
    public fun rain_fall(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.rain_fall }

    public fun city_weather_oracle_geoname_id(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.geoname_id
    }
    public fun city_weather_oracle_name(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): String {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.name
    }
    public fun city_weather_oracle_country(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): String {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.country
    }
    public fun city_weather_oracle_latitude(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.latitude
    }
    public fun city_weather_oracle_longitude(
            weather_oracle: &WeatherOracle, 
            geoname_id: u32
        ): u32 {
            let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
            city_weather_oracle.longitude
        }
    public fun city_weather_oracle_temp(
            weather_oracle: &WeatherOracle,
            geoname_id: u32
        ): u32 {
            let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
            city_weather_oracle.temp
        }
    public fun city_weather_oracle_visibility(
            weather_oracle: &WeatherOracle,
            geoname_id: u32
        ): u16 {
            let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
            city_weather_oracle.visibility
        }
    public fun city_weather_oracle_wind_speed(
            weather_oracle: &WeatherOracle,
            geoname_id: u32
        ): u16 {
            let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
            city_weather_oracle.wind_speed
        }
    public fun city_weather_oracle_wind_deg(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): String {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.wind_deg
    }
    public fun city_weather_oracle_clouds(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u8 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.clouds
    }

    public fun city_weather_oracle_is_rain(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): bool {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.is_rain
    }

    public fun city_weather_oracle_rain_fall(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): String {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.rain_fall
    }


    public fun update_name(_: &AdminCap, weather_oracle: &mut WeatherOracle, name: String) {
        weather_oracle.name = name;
    }

}