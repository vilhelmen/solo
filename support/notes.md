## Bot Strats
* maximize played cards (minimize hand size) - general operation
* maximize opponent hands - close to winning
* minimize opponent turns - close to winning

## Cards
Cards are strings (pairs?) Number, color '1R', '4Y', 'SG'
Sorting this way gives natural groupings for combos

* 1x 0, skip, reverse, draw2 (per color)
* 2x 1-9 (per color)
* 4x wild, wild4



## Card Rankings
* Numbers are neutral and boring
* Skip/reverse/draw is equally boring UNLESS we can punish someone close to winning (3-4 cards remaining)
	* Skip is ideal if the next is close (or we're in 2 player?)
	* Reverse is ideal if the new order maximizes the turns until the closest winner (or we're in 2 player?)
	* Draw is ideal if the next is close (Apparently also is a skip)
* Combos are ideal (play maximization)
	* combos that lead you to a bad color/away from a color you have more of is bad?
		* don't combo to a color you have less of, usually. 30% chance to leave most abundant color?
* Wild cards should be held until needed?
	* Wild+draw is uhhhhh idk, wild and draw I guess
	* color choice is strictly what it has the most of
		* trying to game what the others have is annoying to track and cheating if I just look
			* no card counting!

# Maybe a house rules menu
* technically ending on a wild is illegal
* what does reverse do in 2p?
* comboing draws
