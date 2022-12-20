## Bot goals
* maximize played cards (minimize hand size) - general operation
* maximize opponent hands - close to winning(?)
* minimize opponent turns - close to winning(?)

## Cards
Cards are strings (pairs?) Number, color '1R', '4Y', 'SG'
Sorting this way gives natural groupings for combos

* 1x 0 (per color)
* 2x 1-9, skip, reverse, draw2 (per color)
* 4x wild, wilddraw


## Card Rankings
* Numbers are neutral and boring
* Skip/reverse/draw is equally boring UNLESS we can punish someone close to winning (3-4 cards remaining? factor based on player count?)
	* Skip is ideal if the next is close (or we're in 2 player?)
	* Reverse is ideal if the new order maximizes the turns until the closest winner (or we're in 2 player?)
		* what does reverse do in 2p???
			* one upon a time there was a card so boring everyone died the end
	* Draw is ideal if the next is close (traditionally also a skip??? but that seems lame/easy)
* Combos are ideal (play maximization)
	* combos that lead you to a bad color/away from a color you have more of is bad?
		* don't combo to a color you have less of, usually. 30% chance to leave most abundant color?
* Wild cards should be held until needed?
	* Wild+draw is uhhhhh idk, wild and draw I guess
	* color choice is strictly what it has the most of (10% to pick a different one?)
		* trying to game what the others have is annoying to track and cheating if I just look
			* no card counting!
	* I was under the opinion that, traditionally, ending one wild is illegal but that's undocumented

# Per turn strats
1. Start with set of color matching cards, all are equally likely(?)
	* If the set is 0, uh-oh. Check for wilds, play one (weighted by panic), set color to most abundant (with slight chance of deviation)
		* if there is no wild, oops, draw UNTIL wild or matching color (rip)
			* draw func needs to look for deck exhaustion, discard replenishment, and eventual game end (lol does lua have exceptions)
2. Check (compute) panic level and player observations.
	* someone is near win if they have 3 or 4 cards.
	* Shift from idle play to punishment.
		* Skip is highest priority IFF they are next, otherwise it drops below normal(?)
		* Priority for draw jumps IFF they are next
			* wilddraw > draw? but what color to jump to?
		* Priority for reverse jumps if the new order puts them at disadvantage

## Misc
* Draw till you can play?
* idk if I like that a draw works as a skip
* using a wild to go to the same color, is that a thing?
* what does a reverse do in 2p? - UNDOCUMENTED
* lol there are points!?
* lmao you don't have to play a card but if you don't you have to draw and you don't have to play that but you can't play other hand cards
* wilddraw is an illegal start card, the rest work as expected
* wilddraw says it's illegal if you have other cards of the right color but you can "if you have matching number or action cards"??????

## Maybe a house rules menu
* draw parry
* draw one only
* Configurable initial hand count?
