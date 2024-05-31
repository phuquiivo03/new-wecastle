module wecastle::wecastle {
    use sui::event;
    use std::string::{Self, String};
    use sui::object::{Self, UID, ID};
    use sui::url::{Self, Url};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::package;
    use sui::dynamic_object_field as dof;
    use wecastle::weather as weather_oracle;
    use std::ascii;
    use wecastle::castoken::{CASTOKEN, mint};
    // use wecastle::mission::{GameMission, Work, new, mint_work};
    use sui::pay::{Self};
    use sui::display;

    
    const NOT_A_CORBA_PLAYER: u64 = 1;
    const ENOBALANCE: u64 = 0;
    const INVALID_ID: u64 = 0;
    const ENotDone: u64 = 1;
    const EClaim: u64 = 2;



    public struct Work has key, store {
        id: UID,
        reward: u64,
        done: bool,
        process: u16,

    }

    public struct GetMissionEvent has drop, copy {
        missions: vector<ID>
    }   

    //admin 
    public struct AdminCap has key, store {
        id: UID
    }

    public struct OwnerCap has key, store {
        id: UID
    }

    public struct CorbaGameFi has key { 
        id: UID,
        version: String,
        description: String,
        balance: Balance<CASTOKEN>,
    }

    public struct LeaderBoard has key {
        id: UID,
        min_score: u64,

    }

    public struct CorbaPlayer has key, store {
        id: UID,
        score: u64,
        works: vector<ID>,
    }

    

    //vec <string>


    public struct LoadPlayerEvent has copy, drop {
        id: ID,
        score: u64
    }

    public struct Hero has key, store {
        id: UID,
        type_hero: u16,
        name: String,
        description: String,
        url: Url
    }

    public struct NewHeroEvent has copy, drop {
        id: ID,
        hero_id: ID,
        owner: address
    }

    public struct CityWeatherEvent has drop, copy  {
        id: u32,
        city_name: String,
        country: String,
        temp: u32, 
        visibility: u16, 
        wind_speed: u16,
        wind_deg: String, 
        clouds: u8, 
        is_rain: bool,
        rain_fall: String
    }
    public struct WECASTLE has drop {}
    public struct Rule has drop {}

    fun init(otw: WECASTLE, ctx: &mut TxContext) 
    {
        //hero policy
        let publisher = package::claim<WECASTLE>(otw, ctx);
        let keys = vector[
            b"name".to_string(),
            b"description".to_string(),
            b"image_url".to_string(),
            b"type".to_string()
        ];

        let values = vector[
            b"{name}".to_string(),
            b"{description}".to_string(),
            b"{url}".to_string(),
            b"{type}".to_string(),
        ];

        let mut display = display::new_with_fields<Hero>(
            &publisher, keys, values, ctx
        );
        display::update_version(&mut display);

        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        transfer::public_transfer(display, tx_context::sender(ctx));
        transfer::share_object(CorbaGameFi {
            id: object::new(ctx),
            version: string::utf8(b"1.0"),
            description: string::utf8(b"Corba game"),
            balance: balance::zero<CASTOKEN>(),
        });
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }


    public fun new_player(
        corbaGameFi: &mut CorbaGameFi, 
        ctx: &mut TxContext
    ) {
        let owner_cap = OwnerCap {
            id: object::new(ctx)
        };
        let mut player:  CorbaPlayer = CorbaPlayer {
            id: object::new(ctx),
            score: 0,
            works: vector::empty()
        };
        // let mut mission = new(ctx);
        // mint_work(&mut mission, 0, 6000000, ctx);
        // mint_work(&mut mission, 1, 8000000, ctx);
        // mint_work(&mut mission, 2, 8000000, ctx);
        // mint_work(&mut mission, 3, 10000000, ctx);
        // mint_work(&mut mission, 4, 1300000, ctx);
        // dof::add(
        //     &mut player.id,
        //     string::utf8(b"missions"),
        //     mission
        // );
        event::emit(LoadPlayerEvent {
            id: object::uid_to_inner(&player.id),
            score: 0
        });
        dof::add(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx)), 
            player);
        transfer::public_transfer(owner_cap, tx_context::sender(ctx));
        // init_mission(corbaGameFi, ctx);
        init_mission(corbaGameFi, ctx);
    } 

    public entry fun get_player_data(
        corbaGameFi: &mut CorbaGameFi, 
        ctx: &mut TxContext
    ) {
        let is_created = dof::exists_(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );
        
        if(is_created) {
            let player_info = dof::borrow<ID, CorbaPlayer>(
                &mut corbaGameFi.id, 
                object::id_from_address(tx_context::sender(ctx))
            );
            event::emit(LoadPlayerEvent {
                id: object::uid_to_inner(&player_info.id),
                score: player_info.score
            });
        }else {
            new_player(corbaGameFi, ctx);
        }
    }

    public fun mint_hero(
        _type_hero: u16,
        _name: String,
        _url: Url,
        _description: String,
        ctx: &mut TxContext 
    ): Hero {
        Hero {
            id: object::new(ctx),
            type_hero: _type_hero,
            name: _name,
            description: _description,
            url: _url
        }
    }

    public fun mint_and_stake(
        treasury_cap: &mut TreasuryCap<CASTOKEN>, 
        corba_game: &mut CorbaGameFi,
        amount: u64, 
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        coin::put(&mut corba_game.balance, coin);
    }

    public entry fun purchase(
        _type_hero: u16,
        _name: String,
        _description: String,
        _url: ascii::String,
        _price: u64,
        mut _fee: vector<Coin<CASTOKEN>>,
        corbaGameFi: &mut CorbaGameFi,
        ctx: &mut TxContext 
    ) {
        let is_created = dof::exists_(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );

        assert!(is_created, NOT_A_CORBA_PLAYER);
        let player_info = dof::borrow_mut<ID, CorbaPlayer>(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        ); 

        //update player resources
        let new_hero = mint_hero(
            _type_hero,
            _name,
            url::new_unsafe(_url),
            _description,
            ctx
        );
        let (paid, remainder) = merge_and_split<CASTOKEN>(_fee, _price, ctx);
        let copy_id = object::uid_to_inner(&new_hero.id);
        coin::put(&mut corbaGameFi.balance, paid);

        transfer::public_transfer(remainder, tx_context::sender(ctx));
        transfer::public_transfer(new_hero, tx_context::sender(ctx));

        event::emit(NewHeroEvent {
            id: copy_id,
            hero_id: copy_id,
            owner: tx_context::sender(ctx)
        });
    }

    public entry fun update_score(
        _score: u64,
        corbaGameFi: &mut CorbaGameFi,
        ctx: &mut TxContext,
    ) {
        let player = dof::borrow_mut<ID, CorbaPlayer>(
            &mut corbaGameFi.id, 
            object::id_from_address(tx_context::sender(ctx))
        );
        player.score = player.score + _score;
    }


    public entry fun get_city_weather(city_id: u32, city_weather: &weather_oracle::WeatherOracle) {
        let city_weather = CityWeatherEvent {
            id: city_id,
            city_name: weather_oracle::city_weather_oracle_name(city_weather, city_id),
            country: weather_oracle::city_weather_oracle_country(city_weather, city_id),
            temp: weather_oracle::city_weather_oracle_temp(city_weather, city_id),
            visibility: weather_oracle::city_weather_oracle_visibility(city_weather, city_id),
            wind_speed: weather_oracle::city_weather_oracle_wind_speed(city_weather, city_id),
            wind_deg: weather_oracle::city_weather_oracle_wind_deg(city_weather, city_id),
            clouds: weather_oracle::city_weather_oracle_clouds(city_weather, city_id),
            is_rain: weather_oracle::city_weather_oracle_is_rain(city_weather, city_id),
            rain_fall: weather_oracle::city_weather_oracle_rain_fall(city_weather, city_id),
        };
        event::emit(city_weather);
    }

    fun merge_and_split<CASTOKEN>(
        mut coins: vector<Coin<CASTOKEN>>, amount: u64, ctx: &mut TxContext
    ): (Coin<CASTOKEN>, Coin<CASTOKEN>) {
        
        let mut base = vector::pop_back(&mut coins); 

        pay::join_vec(&mut base, coins);
        let coin_value = coin::value(&base);
        assert!(coin_value >= amount, coin_value);
        (coin::split(&mut base, amount, ctx), base)
    }

    public entry fun claim(amount: u64, game_pool: &mut CorbaGameFi, ctx: &mut TxContext) {
        let mut player = dof::borrow_mut<ID, CorbaPlayer>(
            &mut game_pool.id, 
            object::id_from_address(tx_context::sender(ctx))
        );
        let sender = tx_context::sender(ctx);
        let balance  = balance::value<CASTOKEN>(&game_pool.balance);
        assert!(balance>=amount, ENOBALANCE);
        let reward = coin::take<CASTOKEN>(&mut game_pool.balance, amount, ctx);
        transfer::public_transfer(reward, sender);
        player.score = player.score + amount;
    }


    public entry fun init_mission(
        game : &mut CorbaGameFi,
        ctx: &mut TxContext) {
        // let mut mission = GameMission {
        //     id: object::new(ctx),
        //     works: vector::empty(),
        //     total_works: 0
        // };
        // mint_work(game, 0, 6000000, ctx);
        // mint_work(game, 1, 8000000, ctx);
        // mint_work(game, 2, 8000000, ctx);
        // mint_work(game, 3, 10000000, ctx);
        // mint_work(game, 4, 1300000, ctx);

        let mut player = dof::borrow_mut<ID, CorbaPlayer>(
            &mut game.id,
            object::id_from_address(tx_context::sender(ctx))
        );

        let new_work0 = Work {
            id: object::new(ctx),
            reward: 4000000,
            done: false,
            process: 0
        };
        let new_work1 = Work {
            id: object::new(ctx),
            reward: 4000000,
            done: false,
            process: 0
        };
        let new_work2 = Work {
            id: object::new(ctx),
            reward: 6000000,
            done: false,
            process: 0
        };
        let new_work3 = Work {
            id: object::new(ctx),
            reward: 11000000,
            done: false,
            process: 0
        };
        let new_work4 = Work {
            id: object::new(ctx),
            reward: 14000000,
            done: false,
            process: 0
        };
        vector::insert<ID>(&mut player.works, object::uid_to_inner(&new_work0.id), 0);
        vector::insert<ID>(&mut player.works, object::uid_to_inner(&new_work1.id), 1);
        vector::insert<ID>(&mut player.works, object::uid_to_inner(&new_work2.id), 2);
        vector::insert<ID>(&mut player.works, object::uid_to_inner(&new_work3.id), 3);
        vector::insert<ID>(&mut player.works, object::uid_to_inner(&new_work4.id), 4);
        transfer::public_transfer(new_work0, tx_context::sender(ctx));
        transfer::public_transfer(new_work1, tx_context::sender(ctx));
        transfer::public_transfer(new_work2, tx_context::sender(ctx));
        transfer::public_transfer(new_work3, tx_context::sender(ctx));
        transfer::public_transfer(new_work4, tx_context::sender(ctx));
    }

    // public fun mint_work(
    //     _game: &mut CorbaGameFi, 
    //     _work_id: u64, 
    //     _reward: u64, 
    //     ctx: &mut TxContext) {

    //     let mut player = dof::borrow_mut<ID, CorbaPlayer>(&mut _game.id, object::id_from_address(tx_context::sender(ctx)));
    //     let mut missions = dof::borrow_mut<String, GameMission>(&mut player.id, string::utf8(b"missions"));

    //     let new_work = Work {
    //         id: object::new(ctx),
    //         reward: _reward,
    //         done: false,
    //         process: 0
    //     };
    //     let index = missions.total_works;
    //     vector::insert<ID>(&mut missions.works, object::uid_to_inner(&new_work.id) ,index);
    //     missions.total_works = missions.total_works + 1;
    //     transfer::public_transfer(new_work, tx_context::sender(ctx));
    // }


    public entry fun claim_reward(
        mut _mission:  Work,
        _game: &mut CorbaGameFi,
        ctx: &mut TxContext
    ) {
        assert!(_mission.process == 100, ENotDone);
        assert!(!_mission.done, EClaim);
        claim(_mission.reward, _game, ctx);
        _mission.done = true;
        transfer::public_transfer(_mission, tx_context::sender(ctx));
    }

    public entry fun update_process(
        mut _mission:  Work, 
        _new_process: u16,
        ctx: &mut TxContext
    ) {

        _mission.process = _new_process;
        transfer::public_transfer(_mission, tx_context::sender(ctx));
    }

    
    #[test_only]
    public fun mint_hero_for_test(
        _type_hero: u16,
        _max_health: u16, 
        _damage: u16,
        _speed: u16,
        _exp: u16,
        _max_exp: u16,
        _name: String,
        _description: String,
        _url: vector<u16>,
        ctx: &mut TxContext 
    ): Hero {
        mint_hero(
            _type_hero,
            _max_health,
            _damage,
            _speed,
            _exp,
            _max_exp,
            _name,
            _description,
            url::new_unsafe_from_bytes(_url),
            ctx
        )
    }

    public fun score(player: &CorbaPlayer): &u64 {
        &player.score
    }

    
}

#[test_only]
module game::hero_for_test {
    use game::game::{Self, Hero, CorbaGameFi, CorbaPlayer};
    use sui::dynamic_object_field as dof;
    use sui::test_scenario as ts;
    use sui::transfer;
    use std::string;
    use std::ascii;
    const WARRIOR: u16 = 0;
    const ACHER: u16 = 1;
    const PAWN: u16 = 2;
    const LEVEL_NOT_VALID: u64 = 5;


    #[test]
    public fun mint_hero_test() {
        let add1 = @0xA;
        let add2 = @0xB;
        let mut scenario = ts::begin(add1);
        {

            
            let mut hero = game::mint_hero_for_test(
                PAWN,
                10,
                10,
                10,
                10,
                10,
                string::utf8(b"pawn pro"),
                string::utf8(b"pawn"),
                b"url",
                ts::ctx(&mut scenario),
            );
            transfer::public_transfer(hero, add1);
        };
        ts::next_tx(&mut scenario, add1);
        {
            let mut hero = ts::take_from_sender(&mut scenario);
            game::update_hero(1, 1, 9, 20, 11, 12, 3, 0, 100,  &mut hero, ts::ctx(&mut scenario));
            assert!(game::get_level(&mut hero) == 3, LEVEL_NOT_VALID);
            ts::return_to_sender(&mut scenario, hero);
        };
        ts::end(scenario);
    }

    #[test]
    public fun game_test() {
        let add1 = @0xA;
        let add2 = @0xB;
        let mut scenario = ts::begin(add1);
        {
        //     let corba_game = game::create_corba_game_test(
        //         string::utf8(b"1.0"), 
        //         string::utf8(b"corba gamefi"), 
        //         ts::ctx(&mut scenario)
        //     );
        //     transfer::share_object(corba_game);
        };
        ts::next_tx(&mut scenario, add1);
        {
            // let corbaGameFi = ts::take_from_sender(&mut scenario);
            // let player = CorbaPlayer{
            //     id: ts::ctx(&mut scenario), 
            //     level: 1, 
            //     exp: 0, 
            //     max_exp: 100, 
            //     gold: 0, 
            //     wood: 0, 
            //     meat: 0
            // };
            // dof::add(
            //     &mut corbaGameFi.id,
            //     object::id_from_address(add1), 
            //     player
            // );
        };
         ts::end(scenario);
    }

}

//sponsered fun: new_herro, get_player_data, upadte_hero, update_player_resources, update_player_level
//the rest funs ins normal call
//opackage 0x73725f6b1262eb85047e735921fea7621be5ac3e149cf66dbe8988e4d0bf9aa8
//suiver 0xe67586f62a2249e6b621cddae2c4a7088222801b0e54432dc26a2022054bea5a