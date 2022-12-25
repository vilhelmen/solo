#!/usr/bin/env lua

local math = require "math"
local table = require "table"

math.randomseed(0) -- TODO: switch with appropriate playdate stuff, maybe a debug toggle as well

local PANIC_THRESHOLD = 3  -- 4 or 3????

local DEFAULT_SORT = nil -- it just works
local function DISPLAY_SORT(a, b)
	if a[2] < b[2] then
		return true
	elseif (a[2] == b[2]) then
		return a[1] < b[1]
	else
		return false
	end
end


function build_deck()
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

function shuffle(deck)
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

function initialize(player_count)
	-- boot everything for the primary loop
	deck = build_deck()
	print(table.concat(deck,',')) -- TODO: remove
	shuffle(deck)
	print(table.concat(deck,','))

	discard = {} -- playdate table create!!
	players = {} -- ^

	-- Maybe there will be individual NPCs, track that in here
	for i = 1, player_count do
		table.insert(players,{hand={};id=i})
		-- id is some futureproofing. a function given a player can't tell who it is otherwise
	end

	-- deal hands
	for _ = 1, 7 do
		for i = 1, #players do
			table.insert(players[i].hand, table.remove(deck))
		end
	end
	-- actually idk if I ever really need to do this
	--  no functions are gonna be optimized to take advantage of a sorted order
	-- TODO: remove
	for i = 1, #players do
		table.sort(players[i].hand, DEFAULT_SORT)
	end

	local turn = math.random(#players)
	local order = 1 -- -1 for reverse

	-- make wilddraw an illegal first card
	local first = table.remove(deck)
	while first == 'Xz' do
		-- put it back, somewhere that is NOT the top, pls
		table.insert(deck, math.random(#deck - 1), first)
		first = table.remove(deck)
	end
	-- moving first card to top deck instead of top of discard
	-- this lets us play it using regular flow for rendering
	table.insert(deck, first)
end


-- UHHHHH stomp over the card code if it's wild and the color has been selected?
-- but then you need to remember to reset it
-- otherwise we need an external wild color tracker

function dump()
	print('TOD: ', discard[#discard])
	print('Current player: ', turn)
	print('Order: ', order)
	print('Hands: ')
	for i = 1, #players do
		print('', i, table.concat(players[i].hand, ','))
	end
end

function analyze(whoami)
	-- gather intel
	-- flag everyone near winning
	-- figure out which turn order is better
	-- figure out skip/draw/wild strats
	-- build hand plan?
	local us_losing = false -- panic
	local us_winning = #players[whoami].hand <= PANIC_THRESHOLD
	local us_most_winning = true -- but are we the winningest? Causes panic
	local least_cards = #players[whoami].hand

	local intel = {}
	for i = 1, #players do
		if i ~= whoami then
			-- thankfully our data on other players is VERY limited
			table.inset(intel, {
				winning=#players[i].hand <= PANIC_THRESHOLD,
				most_winning=false, -- touch up after the fact
				total=#players[i].hand, -- ugh I'll need it for nuance
				id=players[i].id,
				-- we are n away from ourself (if included)
				distance=(((whoami - 1) + order * players[i].id) % #players) + 1,
			})
			us_losing = us_losing or intel[#intel].winning
			us_most_winning = us_most_winning and #players[whoami].hand <= #players[i].hand
			if #players[i].hand < least_cards then
				least_cards = #players[i].hand
			end
		end
	end
	-- tag who has the least cards
	for k, v in pairs(intel) do
		if v.total == least_cards then
			v.most_winning = true
		end
	end
	-- sort by distance from us. we may need a mapping to total cards ordering... or just copy it
	table.sort(intel, function(a, b) return a.distance < b.distance end)

	local panic = us_losing or not us_most_winning -- we are, in fact, having a bad time
	local do_punish = intel[1].winning -- attack - basically the same as skip if draw is skip
	local do_skip = false -- attack
	local do_reverse = false -- defend

	if #intel >=2 then -- 3+ total players
		-- local triage = {}
		-- for k,v in pairs(intel) do
		-- 	table.insert(triage, {id=v.id, total=v.total, distance=v.distance,})
		-- end
		-- table.sort(triage, function(a, b) return a.total < b.total end)
		-- checking triage order may be best way to determine moves
		do_skip = intel[2].total > intel[1].total -- so long as we aren't skipping into a better player
		do_reverse = intel[#intel].total > intel[1].total -- sure, if prev has more than next
	else
		do_skip = true -- always good
		do_reverse = false -- at BEST it's not helpful... unless we make it a skip ;)
	end
	-- do we rummage through our playables now?
end


function get_playable(whoami)
	-- Figure out what we can play. Wilds go to the back (read, if top is z you have no choice)
	local playable = {}
	local mask = {}

	for k, v in pairs(players[whoami].hand) do
		if is_playable(v) then
			table.insert(playable, v)
			table.inset(mask, true)
		else
			table.inset(mask, false)
		end
	end

	-- put wilds at the end
	table.sort(playable, DEFAULT_SORT)
	return playable, mask
end


function play_card(card)
	-- uhhhhhhhh I guess we know what turn it is, globally...........
	-- Expect 3-code wilds
	-- blank 3-codes after they are played over (ensure 3code cleared before any draws)
	-- remove card from hand
	-- return true, winner_id on win detection
	-- Apply draw/skip/etc
	return false -- check if nil is needed
end


function draw()
	-- draw dingle card
	-- replenishes deck
	-- can end game
	-- returns card code or nil if game over

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
		return nil
	end
end

function is_playable(card)
	-- same color, same symbol, owned wilds, color matching played wild
	-- a bad lookup is already nil so no need for or nil
	-- an uncoded wild will flag everything as valid
	
	-- what's the performance penalty if 4 lookups/lens
	-- but also lol who cares
	-- kinda ugly when called in a loop
	local current = discard[#discard]
	if (card[2] == current[2]) or (card[1] == current[1]) or (card[2] == 'z') or (card[2] == current[3]) then
		return true
	else
		return false
	end
end

function draw_playable()
	-- draw until playable is found
	-- can end game
	-- returns playable, stack
	-- last card in stack is playable
	-- if playable is false, it's game over
	local drawn = {} -- in theory the maximum is n-3 (tod and one in each player)
	while true do
		-- if I just pushback draw() I might get stuck pushing nil
		local new = draw()
		if new == nil then
			return false, drawn
		end
		table.inset(drawn, new)
		if is_playable(new) then
			return true, drawn
		end
	end
end

-- remove whoami?
function get_color_stats(whoami)
	-- literally only have z so I can loop without it exploding, delete it after
	-- also the "official" color listing is trapped in init. z isn't in it anyway
	-- if I keep a pair with count and color then I can't index via color code without a second mapping
	-- UGH IF I USE THE COLOR AS THE KEY I CAN'T SORT IT DIRECTLY THIS SUCKS
	local colors = {
		{count=0,color='r'}; {count=0,color='b'};
		{count=0,color='g'}; {count=0,color='y'}; {count=0,color='z'}}
	local map = {r=1, b=2, g=3, y=4, z=5}
	for k, v in pairs(players[whoami]) do
		-- TODO: playdate has a +=, use it?
		colors[map[v[2]]].count = colors[map[v[2]]].count + 1
	end
	colors[5] = nil -- BEGONE Z. WIll I regret this? Who knows!
	table.sort(colors, function(a, b) return a.count > b.count end)
	
	return colors
end

-- function force_draw(whoami, count)
-- 	
-- end

function run()
	initialize(4)
	-- TODO need to handle initial wild (do I? it may all be handled now)
	local played = nil

while true do
	played = '??'

	-- playable list is good for bots, mask is good for user
	local playable, mask = get_playable(turn)

	if turn ~= 1 then
		-- LUA DOESN'T HAVE A CONTINUE UGH make this 2 deep and use break?
		if #playable == 0 then
			-- draw until that changes. append it to playable
			-- if we get a wild we gotta run stats on the deck
			local ok, cards = draw_playable() -- the last one has to be playable, the rest are hand-appended
			if not ok then
				-- GAME OVER IDK MAN
				return
			end
			-- IDK!? Leave card in hand, have play_card remove from hand?
			playable = {table.remove(cards)}
			-- move everything LEFT in cards to the end of the hand
			table.move(cards, 1, #cards, #players[turn].hand + 1, players[turn].hand)
			-- need to update player mask??
			-- put this all back in bot logic?
		end

		if #playable == 1 then
			-- just do it. if it's wild, we need to check our numbers
			-- but a full analysis isn't really needed
			if playable[1][2] ~= 'z' then
				played = playable[1]
			else
				-- compute density numbers, play a 3-code wild
				-- TODO: pick second or third with density-based odds?
				local color_density = get_color_stats(turn)
				played = playable[1] .. color_density[1].color
			end
		else
			analyze(turn)
			-- TODO: UGH FIGURE IT OUT
		end
	else
		-- player is human
		-- run a copy of get_playable, have it be a mask?
		-- or just check the cards live
		-- but a mask could let you highlight cards
		-- like, playable cards are bumped up a quarter
		-- or is that too "easy"? hand holdy?
	end
	
	-- cycle turns do whatever else is needed, or halt and return true
	-- return winner number OR zero?
	local game_over, winner = play_card(played)

end end



run()

