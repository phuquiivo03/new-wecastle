// module wecastle::leaderboard {
//     use std::vector;

//     use sui::object::{Self, ID, UID};
//     use sui::tx_context::{TxContext};
//     use sui::transfer;

//     use wecastle::wecastle::{Self, CorbaPlayer};

//     const ENotALeader: u64 = 0;
//     const ELowTile: u64 = 1;
//     const ELowScore: u64 = 2;

//     struct Leaderboard has key, store {
//         id: UID,
//         size: u64,
//         players: vector<TopPlayer>,
//         min_score: u64
//     }

//     struct TopPlayer has store, copy, drop {
//         leader_address: address,
//         score: u64
//     }

//     fun init(ctx: &mut TxContext) {
//         create(ctx);
//     }

//     // ENTRY FUNCTIONS //

//     public entry fun create(ctx: &mut TxContext) {
//         let leaderboard = LeaderBoard {
//             id: object::new(ctx),
//             size: 20,
//             players: vector<TopPlayer>[],
//             min_score: 0
//         };
//         transfer::share_object(leaderboard);
//     }

//     public entry fun submit_game(player: &mut CorbaPlayer, leaderboard: &mut LeaderBoard) {
//         let score = *wecastle::score(player);

//         if(score > leaderboard.min_score) {

//             //tao 1 func de  lay tham chieu address cua phayer
//             let leader_address = *wecastle::player(player);

//             let top_player = TopPlayer {
//                 leader_address,
//                 score: *wecastle::score(player),
//             };
//             add_top_player_sorted(leaderboard, top_player);
//         }

//     }

//     // PUBLIC ACCESSOR FUNCTIONS //

//     public fun game_count(leaderboard: &LeaderBoard): u64 {
//         vector::length(&leaderboard.top_players)
//     }

//     public fun top_players(leaderboard: &LeaderBoard): &vector<TopPlayer> {
//         &leaderboard.top_players
//     }

//     public fun top_player_at(leaderboard: &LeaderBoard, index: u64): &TopPlayer {
//         vector::borrow(&leaderboard.top_players, index)
//     }

//     public fun top_player_at_has_id(leaderboard: &LeaderBoard, index: u64, game_id: ID): bool {
//         let top_player = top_player_at(leaderboard, index);
//         top_player.game_id == game_id
//     }

//     public fun top_player_game_id(top_player: &TopPlayer): ID {
//         top_player.game_id
//     }

//     public fun top_player_top_tile(top_player: &TopPlayer): &u64 {
//         &top_player.top_tile
//     }

//     public fun top_player_score(top_player: &TopPlayer): &u64 {
//         &top_player.score
//     }

//     public fun min_tile(leaderboard: &LeaderBoard): &u64 {
//         &leaderboard.min_tile
//     }

//     public fun min_score(leaderboard: &LeaderBoard): &u64 {
//         &leaderboard.min_score
//     }

//     fun add_top_player_sorted(leaderboard: &mut LeaderBoard, top_player: TopPlayer) {
//         let top_players = leaderboard.players;
//         let top_players_length = vector::length(&top_players);

//         let index = 0;
//         while (index < top_players_length) {
//             let current_top_player = vector::borrow(&top_players, index);
//             if (top_player.leader_address == current_top_player.leader_address) {
//                 vector::swap_remove(&mut top_players, index);
//                 break
//             };
//             index = index + 1;
//         };

//         vector::push_back(&mut top_players, top_player);

//         top_players = merge_sort_top_players(top_players); 
//         top_players_length = vector::length(&top_players);

//         if (top_players_length > leaderboard.max_leaderboard_game_count) {
//             vector::pop_back(&mut top_players);
//             top_players_length  = top_players_length - 1;
//         };

//         if (top_players_length >= leaderboard.max_leaderboard_game_count) {
//             let bottom_game = vector::borrow(&top_players, top_players_length - 1);
//             leaderboard.min_tile = bottom_game.top_tile;
//             leaderboard.min_score = bottom_game.score;
//         };

//         leaderboard.top_players = top_players;
//     }

//     public(friend) fun merge_sort_top_players(top_players: vector<TopPlayer>): vector<TopPlayer> {
//         let top_players_length = vector::length(&top_players);
//         if (top_players_length == 1) {
//             return top_players
//         };

//         let mid = top_players_length / 2;

//         let right = vector<TopPlayer>[];
//         let index = 0;
//         while (index < mid) {
//             vector::push_back(&mut right, vector::pop_back(&mut top_players));
//             index = index + 1;
//         };

//         let sorted_left = merge_sort_top_players(top_players);
//         let sorted_right = merge_sort_top_players(right);
//         merge(sorted_left, sorted_right)
//     }

//     public(friend) fun merge(left: vector<TopPlayer>, right: vector<TopPlayer>): vector<TopPlayer> {
//         vector::reverse(&mut left);
//         vector::reverse(&mut right);

//         let result = vector<TopPlayer>[];
//         while (!vector::is_empty(&left) && !vector::is_empty(&right)) {
//             let left_item = vector::borrow(&left, vector::length(&left) - 1);
//             let right_item = vector::borrow(&right, vector::length(&right) - 1);

//             if (left_item.top_tile > right_item.top_tile) {
//                 vector::push_back(&mut result, vector::pop_back(&mut left));
//             } else if (left_item.top_tile < right_item.top_tile) {
//                 vector::push_back(&mut result, vector::pop_back(&mut right));
//             } else {
//                 if (left_item.score > right_item.score) {
//                     vector::push_back(&mut result, vector::pop_back(&mut left));
//                 } else {
//                     vector::push_back(&mut result, vector::pop_back(&mut right));
//                 }
//             };
//         };

//         vector::reverse(&mut left);
//         vector::reverse(&mut right);
        
//         vector::append(&mut result, left);
//         vector::append(&mut result, right);
//         result
//     }
    

//     // TEST FUNCTIONS //

//     #[test_only]
//     use sui::test_scenario::{Self, Scenario};

//     #[test_only]
//     public fun blank_leaderboard(scenario: &mut Scenario, max_leaderboard_game_count: u64, min_tile: u64, min_score: u64) {
//         let ctx = test_scenario::ctx(scenario);
//         let leaderboard = LeaderBoard {
//             id: object::new(ctx),
//             max_leaderboard_game_count: max_leaderboard_game_count,
//             top_players: vector<TopPlayer>[],
//             min_tile: min_tile,
//             min_score: min_score
//         };

//         transfer::share_object(leaderboard)
//     }

//     #[test_only]
//     public fun top_player(scenario: &mut Scenario, leader_address: address, top_tile: u64, score: u64): TopPlayer {
//         let ctx = test_scenario::ctx(scenario);
//         let object = object::new(ctx);
//         let game_id = object::uid_to_inner(&object);
//         sui::test_utils::destroy<sui::object::UID>(object);
//         TopPlayer {
//             game_id,
//             leader_address,
//             top_tile,
//             score
//         }
//     }
// }