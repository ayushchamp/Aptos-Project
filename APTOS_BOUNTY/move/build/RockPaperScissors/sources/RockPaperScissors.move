address 0x866c550959ec820338ecca5ae138b7ac82dd0107d72cfd24219b84168a3d75b3 {

module RockPaperScissors {
    use std::signer;
    use aptos_framework::randomness;

    const ROCK: u8 = 1;
    const PAPER: u8 = 2;
    const SCISSORS: u8 = 3;

    struct Game has key {
        player: address,
        player_move: u8,   
        computer_move: u8,
        result: u8,
    }

    struct Scores has key {
        player_wins: u64,
        computer_wins: u64,
    }

    public entry fun start_game(account: &signer) {
        let player = signer::address_of(account);

        let game = Game {
            player,
            player_move: 0,
            computer_move: 0,
            result: 0,
        };

        move_to(account, game);

        // Initialize scores for the player if they don't exist
        if (!exists<Scores>(player)) {
            let scores = Scores {
                player_wins: 0,
                computer_wins: 0,
            };
            move_to(account, scores);
        }
    }

    public entry fun set_player_move(account: &signer, player_move: u8) acquires Game {
        let game = borrow_global_mut<Game>(signer::address_of(account));
        game.player_move = player_move;
    }

    #[randomness]
    entry fun randomly_set_computer_move(account: &signer) acquires Game {
        randomly_set_computer_move_internal(account);
    }

    public(friend) fun randomly_set_computer_move_internal(account: &signer) acquires Game {
        let game = borrow_global_mut<Game>(signer::address_of(account));
        let random_number = randomness::u8_range(1, 4);
        game.computer_move = random_number;
    }

    public entry fun finalize_game_results(account: &signer) acquires Game, Scores {
        let game = borrow_global_mut<Game>(signer::address_of(account));
        let result = determine_winner(game.player_move, game.computer_move);
        game.result = result;

        // Update scores based on result
        let scores = borrow_global_mut<Scores>(signer::address_of(account));
        if (result == 2) {
            scores.player_wins = scores.player_wins + 1;
        } else if (result == 3) {
            scores.computer_wins = scores.computer_wins + 1;
        }
    }

    public entry fun reset_game(account: &signer) acquires Game {
        let player = signer::address_of(account);

        if (exists<Game>(player)) {
            let game = borrow_global_mut<Game>(player);
            game.player_move = 0;
            game.computer_move = 0;
            game.result = 0;
        }
    }

    fun determine_winner(player_move: u8, computer_move: u8): u8 {
        if (player_move == ROCK && computer_move == SCISSORS) {
            2 // player wins
        } else if (player_move == PAPER && computer_move == ROCK) {
            2 // player wins
        } else if (player_move == SCISSORS && computer_move == PAPER) {
            2 // player wins
        } else if (player_move == computer_move) {
            1 // draw
        } else {
            3 // computer wins
        }
    }

    #[view]
    public fun get_player_move(account_addr: address): u8 acquires Game {
        borrow_global<Game>(account_addr).player_move
    }

    #[view]
    public fun get_computer_move(account_addr: address): u8 acquires Game {
        borrow_global<Game>(account_addr).computer_move
    }

    #[view]
    public fun get_game_results(account_addr: address): u8 acquires Game {
        borrow_global<Game>(account_addr).result
    }

    #[view]
    public fun get_player_score(account_addr: address): u64 acquires Scores {
        borrow_global<Scores>(account_addr).player_wins
    }

    #[view]
    public fun get_computer_score(account_addr: address): u64 acquires Scores {
        borrow_global<Scores>(account_addr).computer_wins
    }
}
}
