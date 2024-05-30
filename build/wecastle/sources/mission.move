module wecastle::mission{
    use sui::coin::{Coin, Self, TreasuryCap};
    use sui::tx_context::{TxContext, Self};
    use sui::object::{UID};
    use sui::transfer;
    use sui::url::{Self, Url};
    use wecastle::castoken::{CASTOKEN, mint};
    use sui::balance::{Self, Balance};
    use std::string::{String};
    use sui::dynamic_object_field as dof;
    use sui::package;
    use sui::display;
    use wecastle::wecastle::{CorbaGameFi, claim};


    const INVALID_ID: u64 = 0;
    const ENotDone: u64 = 1;
    const EClaim: u64 = 2;
    public struct GameMission has key {
        id: UID,
        total_works: u64
    }

    public struct Work has key, store {
        id: UID,
        reward: u64,
        done: bool,
        process: u16,

    }

    public struct MISSION  has drop { }

    fun init(otw: MISSION, ctx: &mut TxContext) {
        
        let publisher = package::claim(otw, ctx);
  
        transfer::share_object(GameMission{
            id: object::new(ctx), 
            total_works: 0
        });
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    public entry fun mint_work(
        _game_mission: &mut GameMission, 
        _work_id: u64, 
        _reward: u64, 
        ctx: &mut TxContext) {
        let is_existed = dof::exists_<u64>(&_game_mission.id, _work_id);
        assert!(!is_existed, INVALID_ID);
        let new_work = Work {
            id: object::new(ctx),
            reward: _reward,
            done: false,
            process: 0
        };
        dof::add(&mut _game_mission.id, _work_id, new_work); 
        _game_mission.total_works = _game_mission.total_works + 1;
    }

    public entry fun claim_reward(
        _game_mission: &mut GameMission, 
        _game_pool: &mut CorbaGameFi,
        _mission_id: u64,
        ctx: &mut TxContext
    ) {
        let mut mission = dof::borrow_mut<u64, Work>(&mut _game_mission.id, _mission_id);
        assert!(mission.process == 100, ENotDone);
        assert!(!mission.done, EClaim);
        claim(mission.reward, _game_pool, ctx);
        mission.done = true;
    }

    public entry fun update_porecess(
        _game_mission: &mut GameMission, 
        _mission_id: u64,
        _new_process: u16,
        ctx: &mut TxContext
    ) {
        let mut mission = dof::borrow_mut<u64, Work>(&mut _game_mission.id, _mission_id);
        if(mission.process < 100) {
            if(_new_process > 100) {
                mission.process = 100;
            }else {
                mission.process = _new_process;
            }
        }
    }


    
}