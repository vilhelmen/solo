#!/usr/bin/env lua

local math = require "math"
local table = require "table"

math.randomseed(0) -- TODO: switch with appropriate playdate stuff, maybe a debug toggle as well

local PANIC_THRESHOLD = 3  -- 4 or 3???? 4-(n//2)? (n//2)+2?

local DEFAULT_SORT = nil -- it just works
-- fix color ordering with a map?
--  alphabetical would be uhhhhhhhhhh b g r y
--  ........ but also we don't have a color display
--  colors are just, like, your opinion, man
local function DISPLAY_SORT(a, b)
	if a:sub(2) < b:sub(2) then
		return true
	elseif (a:sub(2) == b:sub(2)) then
		return a:sub(1) < b:sub(1)
	else
		return false
	end
end


local function build_deck()
	local singles = {'0'} -- multiply by color
	local doubles = {'1','2','3','4','5','6','7','8','9','D','R','S'} -- multiply by color by 2
	local quads = {'W','X'} -- 4 of each, null color. I don't like X but I need something that comes after W
	local colors = {'r','y','g','b'} -- capitalization?
	-- this should make a reasonable ordering when sorted as well. Handy.
	-- Color should be added to the back for better planning, but should be reversed for user display maybe

	local deck = {} -- TODO: change to playdate table create func

	-- I have decided I do not like lua
	for _, pass_color in pairs(colors) do
		for _, v in pairs(singles) do
			table.insert(deck, v .. pass_color)
		end
		for _, v in pairs(doubles) do
			table.insert(deck, v .. pass_color)
			table.insert(deck, v .. pass_color)
		end
		for _, v in pairs(quads) do
			table.insert(deck, v .. 'z')
		end
	end
	return deck
end

local function shuffle(deck)
	-- lua is pass by ref so this makes calling a little ugly.
	-- Don't think there's a case where I should deepcopy or whatever
	-- UGH fisher-yates is FINE
	-- there's a notable tendency to swap with itself towards the end but whatever
	-- no point to iteration i=1 since it always self swaps
	local j
	for i = #deck, 2, -1 do
		j = math.random(i)
		deck[i], deck[j] = deck[j], deck[i]
	end
end


 -- TODO: playdate table create in the appropriate places
 -- I'm absolutely DISGUSTED I'm keeping these in this scope
 --  this is what happens when you take away my objects, civility is gone

local deck = nil
local discard = nil
local players = nil
local turn = nil
local order = nil

local function initialize(player_count)
	-- boot everything for the primary loop
	deck = build_deck()
	print(table.concat(deck,',')) -- TODO: remove
	shuffle(deck)
	print(table.concat(deck,','))

	discard = {} -- playdate table create!!
	players = {} -- ^

	-- Maybe there will be individual NPCs, track that in here
	for i = 1, player_count do
		table.insert(players, {hand={}, id=i})
		-- id is some futureproofing. a function given a player can't tell who it is otherwise
	end

	-- deal hands
	for _ = 1, 7 do
		for _, p in ipairs(players) do
			table.insert(p.hand, table.remove(deck))
		end
	end
	-- actually idk if I ever really need to do this
	--  no functions are gonna be optimized to take advantage of a sorted order
	-- TODO: remove
	for _, p in ipairs(players) do
		table.sort(p.hand, DEFAULT_SORT)
	end

	turn = math.random(#players)
	order = 1 -- -1 for reverse

	-- make wilddraw an illegal first card
	local first = table.remove(deck)
	while first == 'Xz' do
		-- put it back, somewhere that is NOT the top, pls
		table.insert(deck, math.random(#deck - 1), first)
		first = table.remove(deck)
	end

	table.insert(discard, first)
end


local function deduplicate_cards(card_pile)
	-- deduplicate a list of cards
	local singles = {}
	for _, v in pairs(card_pile) do
		singles[v] = true -- I can't imagine a value that would matter/save time
	end
	local dedupe = {}
	for v, _ in pairs(singles) do
		table.insert(dedupe, v)
	end
	return dedupe
end


local function is_normal(card)
	-- technically we don't have anything below '0' at the moment since + is now X
	return card:sub(1) <= '9' and card:sub(1) >= '0'
end

local function is_special(card)
	return not is_normal(card) -- get owned
end


local function get_color_stats(card_pile)
	-- returns playable color breakdown, color map, and z breakdown
	-- reminder that playable is deduplicated
	local color_log = { -- no need for special if we have the flags?
		{normal={}, special={}, D=false, R=false, S=false, color='r', total=0};
		{normal={}, special={}, D=false, R=false, S=false, color='g', total=0};
		{normal={}, special={}, D=false, R=false, S=false, color='b', total=0};
		{normal={}, special={}, D=false, R=false, S=false, color='y', total=0};
		{normal={}, special={}, W=false, X=false, color='z', total=0}
	} -- z normal list for easier processing
	local index_map = {r=1, g=2, b=3, y=4, z=5}

	-- ok, big brain time.
	-- a foreign color can only be hand-dominant iff ...?
	--  we have none of the current color (we can really only have one of a foreign color, playable is deduped)
	--  current card is a wildstart -- technically no color is foreign?

	for _, v in pairs(card_pile) do
		if is_normal(v) then -- no z is normal
			table.insert(color_log[index_map[v:sub(2)]].normal, v)
		else
			table.insert(color_log[index_map[v:sub(2)]].special, v)
			color_log[index_map[v:sub(2)]][v:sub(1)] = true
		end
		color_log[index_map[v:sub(2)]].total = color_log[index_map[v:sub(2)]].total + 1
	end

	-- UGH z consistently clouds judgement, pull it out
	local z_log = color_log[index_map.z]
	color_log[index_map.z] = nil
	index_map.z = nil
	if z_log.total == 0 then
		z_log = nil
	end

	-- pruning post-sort because I'm a terrible person
	table.sort(color_log, function(a, b) return a.total < b.total end)
	while color_log[#color_log].total == 0 do
		table.remove(color_log)
	end

	-- rebuild index
	index_map = {}
	for i, v in ipairs(color_log) do
		index_map[v.color] = i
	end

	return color_log, index_map, z_log
end


local function dump()
	print('TOD: ', discard[#discard])
	print('Current player: ', turn)
	print('Order: ', order)
	print('Hands: ')
	for i, v in ipairs(players) do
		print('', i, table.concat(v.hand, ','))
	end
end


local function get_good_colors(hand_color_stats)
	-- return color codes (desc) that are comparable in size to the largest
	-- big brain time, if you have > 50% as many red as blue, then both look good
	-- 6 and 2? Totally unequal. 6 and 3? close but eh. 6 and 4? sure!
	-- 100 and 51? ehhh
	local colors = {hand_color_stats[1].color} -- should probably check if this is empty
	local threshold = hand_color_stats[1].total // 2 -- +1, >= ?
	-- I'm not smart enough to start pairs() at 2. next(pairs())??? (no)
	for i = 2, #hand_color_stats do
		if hand_color_stats[i].color > threshold then
			table.insert(colors, hand_color_stats[i].color)
		end
	end
end


local function get_good_color_card(good_colors, hand_color_stats, hand_color_map)
	-- picks a card from a good color. prefers normies.
	local color_choice = hand_color_stats[hand_color_map[good_colors[math.random(#good_colors)]]]
	if #color_choice.normal ~= 0 then
		return color_choice.normal[math.random(#color_choice.normal)]
	else
		return color_choice.special[math.random(#color_choice.special)]
	end
end

local function is_not_in(list, object)
	-- LUA PLEASE
	for _, v in ipairs(list) do
		if v == object then
			return false
		end
	end
	return true
end

-- UGH IN IS A RESERVED WORD
local function is_in(list, object)
	return not is_not_in(list, object)
end


local function analyze(playable)
	-- do, like, everything

	-- Uhhh don't draw here because it complicates the return
	--  if we gotta return a winner
	--  unless we switch back to exceptions. Or I just return a second thing.
	-- but a draw coming into here will short circuit:

	-- we really only have one option
	local deduplicated_playable = deduplicate_cards(playable)
	if #deduplicated_playable == 1 then
		-- but it might be a wild
		if deduplicated_playable[1]:sub(2) ~= 'z' then
			return deduplicated_playable[1]
		end

		local good_colors = get_good_colors(get_color_stats())
		-- ...and we may only have wilds in our hand (this may be the last card)
		if #good_colors ~= 0 then
			-- it HAS to go into a variable to be used
			-- 'rgby':sub(math.random(4)) is illegal
			good_colors = {'r', 'g', 'b', 'y'}
		end
		return deduplicated_playable[1] .. good_colors[math.random(#good_colors)]
	end

	local us_losing = false -- panic
	local us_winning = #players[turn].hand <= PANIC_THRESHOLD
	local us_most_winning = true -- but are we the winningest? Causes panic
	local least_cards = #players[turn].hand

	local intel = {}
	for i, p in ipairs(players) do
		if i ~= turn then
			-- thankfully our data on other players is VERY limited
			table.insert(intel, {
				winning=#p.hand <= PANIC_THRESHOLD,
				most_winning=false, -- touch up after the fact
				total=#p.hand, -- ugh I'll need it for nuance
				id=p.id,
				-- we are n away from ourself (if included)
				distance=(((turn - 1) + order * p.id) % #players) + 1,
			})
			us_losing = us_losing or intel[#intel].winning
			us_most_winning = us_most_winning and #players[turn].hand <= #p.hand
			if #p.hand < least_cards then
				least_cards = #p.hand
			end
		end
	end
	-- tag who has the least cards
	for _, v in pairs(intel) do
		if v.total == least_cards then
			v.most_winning = true
		end
	end
	-- sort by distance from us. we may need a mapping to total cards ordering... or just copy it
	table.sort(intel, function(a, b) return a.distance < b.distance end)

	local panic = us_losing or not us_most_winning -- we are, in fact, having a bad time
	-- remove most_winning override? Don't get complacent!
	local do_punish = intel[1].winning -- attack - basically the same as skip if draw is skip
	local do_skip = false -- attack by defending (lol)
	local do_reverse = false -- defend
	-- all draws are skips which makes punish/skip fights frustrating
	-- combine skip/punish?

	-- skips are better than reverse (unless it makes us beef it directly ("notable" difference in total?))
	--  because it minimizes turns

	if #intel == 3 then
		-- don't skip if the person we jump to is better off... but what about the person after THEM
		--  a turn, in theory, is -1 to all. Skipping blocks their -1
		--  but what if the third is about to win, we want to maximize turns before them?
		do_skip = intel[2].total > intel[1].total and intel[1].total <= intel[3].total
		-- don't reverse if the reverse is doing better under panic
		do_reverse = intel[#intel].total > intel[1].total
	elseif (#intel == 2) then
		-- don't skip to someone of higher criticality, ideally
		-- these rules only really apply under panic
		do_skip = intel[2].total > intel[1].total
		do_reverse = intel[#intel].total > intel[1].total
	else
		do_punish = true -- get dunked on. There's one enemy and it's you :dagger:
		do_skip = true -- always good
		do_reverse = not panic -- or us_most_winning
		-- at BEST it's not helpful... 2p-normification is needed
		-- ^ this ^ probably won't get picked up right, make it trinary? Check player count on read?
	end

	local current_color = discard[#discard]:sub(2)
	if current_color == 'z' then
		current_color = discard[#discard]:sub(3)
		-- we may still be wildstart, but we need more hand info before we can handle it
	end

	local to_play = nil
	-- local priority_list = {}

	-- big brain, playable_z is strictly worse than hand_z because it's deduplicated
	local playable_color_stats, playable_color_map = get_color_stats(playable)

	-- there is NO reason to consider Z in hand_color UNLESS you're in 2p fishing for Wz combos
	--  or, perhaps, in panic
	-- is 2p going to be its own primary logic that fishes for combos?
	-- TODO: let this return a list of cards in 2p mode?
	--  loop outside play_card and raise if turn changes?
	local hand_color_stats, hand_color_map, hand_z = get_color_stats(players[turn].hand)
	local good_colors = get_good_colors(hand_color_stats)

	if #hand_color_stats == 0 then
		if hand_z == nil then
			-- how did this happen
			error('Bot has nothing to play???')
		end
		-- Unknown combination of z cards
		-- pick X based on do_punish

		-- Big brain time: if you have W and X, does the order really matter?
		-- in a geologic sense, the +4 happens either way
		-- a later +4 minimizes their average play space

		-- I do no like manufacturing the card code
		if do_punish and hand_z.X then
			to_play = 'Xz'
		elseif (hand_z.W) then
			to_play = 'Wz'
		else
			to_play = 'Xz'
		end

		return to_play .. good_colors[math.random(#good_colors)]
	end

	-- as of here, we have at least two distinct cards at least one of which is non-z
	--  spread across at least one color, which may or may not be the current color
	-- good luck

	-- identify_jumpable() ?

	-- local can_jump = #good_colors > 1 -- not wholly accurate since it's using good_colors
	local only_jump = playable_color_map[current_color] == nil -- current color not in index
	local should_jump = is_not_in(good_colors, current_color) and
		(playable_color_stats[playable_color_map[current_color]].total > 2 or math.random(5) == 5) and
		playable_color_stats[playable_color_map[current_color]].total ~= 1
	-- we may not be in the top color, but we're comparable. But hold out if we only have <= two left
	--  set holdout to random chance, say 80%?
	--   I don't like the idea of jumping if it was literally the last of that color tho
	--    IDK!
	-- if it's not a good color, we know we have at least double of the other color
	--  maybe that plays into holdout, some sort of sliding % based on current total
	--   but also, 1 and 2 cards is the borderline of panic

	-- I feel like panic should override should_jump maybe? But only if we have a strategic play?
	--  one could consider a color change strategic tho, but is it better than direct punishment (if available)
	if only_jump or current_color == nil or (should_jump and not panic) then
		-- none of current color, or wildstart, or current color is not good
		return get_good_color_card(good_colors, hand_color_stats, hand_color_map)
	end


	-- UHHH the inverse of good_colors? Any color that has (strictly?) more cards
	--  but what if we only have one left of the current color. or 2?
	-- should jump if any color with a higher color map index number exists in playable
	--  AND we aren't sufficiently low on the current

	-- IN THEORY, we should only have one card of each jumpable color
	--  wildstart has been handled, and we can only jump if the symbol matches
	--  We could be burning something of value in order to jump

	if not panic then
		-- check if we should jump colors (if possible)
		
		
		
		-- if that's not interesting, just play whatever we have in the current color, snore
		--  if we have no normies, or on % chance, add specials into the choice
		
	else
		-- FRICK. have to rank our options vs do_ codes
	end

	-- if we can play a normal card, then ignore z? Unless panic and Xz?

	-- rank all specials according to panic logic and play first that exists?
	-- specials could still be cross-color, need color state and crossing data
	-- if we're not panic, ignore specials? Low-rank them?
	
	-- lol fun idea, bots get a boredom counter that makes them play specials with increasing %
end


local function is_playable(card)
	-- same color, same symbol, owned wilds, color matching played wild
	-- a bad lookup is already nil so no need for or nil
	-- an uncoded wild will flag everything as valid

	-- what's the performance penalty if 4 lookups/lens
	-- but also lol who cares
	-- kinda ugly when called in a loop
	local current = discard[#discard]
	if (card:sub(2) == current:sub(2)) or (card:sub(1) == current:sub(1)) or
			(card:sub(2) == 'z') or (card:sub(2) == current:sub(3)) then
		return true
	else
		return false
	end
end


local function get_playable()
	-- returns list of playable cards, and boolean hand mask
	local playable = {}
	local mask = {}

	for _, v in pairs(players[turn].hand) do
		if is_playable(v) then
			table.insert(playable, v)
			table.insert(mask, true)
		else
			table.insert(mask, false)
		end
	end

	-- put wilds at the end
	-- FIXME: do we notably rely on this anywhere? Remove it.
	-- table.sort(playable, DEFAULT_SORT)
	return playable, mask
end


local function find_winner()
	-- deck exhaustion is ambiguous and there could be a tie
	local min_hand = #players[1].hand
	for i = 2, #players do
		if #players[i].hand < min_hand then
			min_hand = #players[i].hand
		end
	end
	local winners = {}
	for i, p in ipairs(players) do
		if #p.hand == min_hand then
			table.insert(winners, i)
		end
	end
	return winners
end


local function draw()
	-- draw single card, refill deck when needed.
	-- returns card code or nil on exhaust

	-- in theory, deck exhaustion doesn't have to be game over if no one ever draws again
	-- refill before return, so if it's empty now, you're out
	if #deck > 1 then
		return table.remove(deck)
	elseif #deck == 1 then
		local hold = table.remove(deck)
		local tod = table.remove(discard)
		-- well, if the discard is empty this will all no-op
		shuffle(discard)
		table.move(discard, 1, #discard, 1, deck)
		table.insert(discard, tod)
		return hold
	else
		-- raising really just made the callees more complex for VERY little gain :c
		-- error('deck_exhaust')
		return nil
	end
end


local function play_card(card)
	-- uhhhhhhhh I guess we know what turn it is, globally...........
	-- Expect 3-code wilds
	-- blank 3-codes after they are played over (ensure 3code cleared before any draws)
	-- remove card from hand
	-- Apply draw/skip/etc
	-- returns winner vector or nil

	-- place ToD
	table.insert(discard, card)
	-- Strip any 3codes
	discard[#discard - 1] = string.sub(discard[#discard - 1], 1, 2)
	card = string.sub(card, 1, 2)
	-- sanity check for fake cards, bot logic may end up building card strings :/
	local did_eject = false
	for i = 1, #players[turn].hand do
		if #players[turn].hand[i] == card then
			table.remove(players[turn].hand, i)
			did_eject = true
			break
		end
	end
	if not did_eject then
		-- tbh maybe I should raise
		error('Illegal play: ' .. card)
		-- print('AAAAA fake card', card)
	end

	-- only the playing person can win right now
	if #players[turn].hand == 0 then
		return {turn}
	end

	-- order should be:
	-- reverse
	-- turn cycle
	-- force draw
	--  anyone can win when applying a draw
	-- skip apply

	if card:sub(1) == 'R' then
		order = order * -1
	end

	turn = (((turn - 1) + order) % #players) + 1

	local to_draw = 0
	if card:sub(1) == 'D' then
		to_draw = 2
	elseif card:sub(1) == 'X' then
		to_draw = 4
	end
	if to_draw ~= 0 then
		local drawn = {}
		for _ = 1, to_draw do
			-- whatever, I can check a nil later
			table.insert(drawn, draw())
		end
		if #drawn ~= to_draw then
			-- FRICK, exhaustion, GAME OVER MAN, GAME OVER
			return find_winner()
		else
			table.move(drawn, 1, #drawn, #players[turn].hand + 1, players[turn].hand)
		end
	end

	if card:sub(1) == 'S' or card:sub(1) == 'D' or card:sub(1) == 'X' then -- not all Z, just X
		-- shift to 0-base, apply rotation, then shift back ;)
		turn = (((turn - 1) + order) % #players) + 1
	end

	return nil -- do I have to explicitly return nil?
end


local function draw_playable()
	-- draw until a playable is reached, appending to hand
	-- returns playable card or nil on exhaust
	local card
	while true do
		card = draw()
		-- is_playable can't handle nil probably
		-- and I kinda don't want to add support because that's gonna be a busy function
		if card == nil then
			-- by the time I found out I could raise it only made the code messier :(
			return nil
		end
		table.insert(players[turn].hand, card)
		if is_playable(card) then
			break
		end
	end
	return card
end


local function run(n)
	initialize(n)
	-- FIXME: debug stuff, skip player
	turn = 2
	dump()
	-- TODO check initial wild (should be secretly handled by get_playable)

while true do
	local played, forced_play = '??', false

	-- playable list is good for bots, mask is good for user
	local playable, mask = get_playable()

	if #playable == 0 then
		-- mask is garbage now
		local drawn = draw_playable()
		forced_play = true
		if played == nil then
			return find_winner()
		end
		playable = {drawn}
	end

	if turn ~= 1 then
		-- offloading single-play, etc
		analyze(playable)
		-- TODO: UGH FIGURE IT OUT
	else
		-- player is human
		-- run a copy of get_playable, have it be a mask?
		-- or just check the cards live
		-- but a mask could let you highlight cards
		-- like, playable cards are bumped up a quarter
		-- or is that too "easy"? hand holdy?
	end

	local winner = play_card(played)
	if winner ~= nil then
		return winner
	end
end end


print(run(4))
-- require "croissant.debugger"()

-- best idea, menu entry for ending game
-- multi-stage tableflip anim, a to progress, b to cancel
-- sit -(A)> stand -(A)> flip.
-- def have an upside down 7 card visible
