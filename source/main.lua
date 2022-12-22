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

print("Deck init")

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

local deck = build_deck()
print(table.concat(deck,','))
shuffle(deck)
print(table.concat(deck,','))

local discard = {} -- TODO: playdate table create
-- just setting it to 4 for now
local players = {} -- ^^
for i = 1, 4 do
	table.insert(players,{hand={};id=i})
	-- id is some futureproofing. a function given a player can't tell who it is otherwise
end

-- deal hands
for _ = 1, 7 do
	for i = 1, #players do
		table.insert(players[i].hand, table.remove(deck))
	end
end
for i = 1, #players do
	table.sort(players[i].hand, DEFAULT_SORT)
end

local turn = math.random(#players)
local order = 1 -- -1 for reverse

do
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


function draw(whoami)
	-- draw until playable, checking deck exhaustion and maybe game end
	-- return set of drawn cards, final one should be playable. Nil if game over
	-- !!!!!! make sure any wild drawn isn't a 3code
	--  which is to say be sure to purge 3codes on discard shuffle
	nil
end

function can_play(whoami)
	-- Figure out what we can play. Wilds go to the back (read, if top is z you have no choice)
	local playable = {}

	for k, v in pairs(players[whoami].hand) do
		-- same color, same symbol, owned wilds, color matching played wild
		-- Assume unset wilds have been handled.
		local current = discard[#discard]
		-- do we include wilds now or hunt later? Put them on the end?
		-- a bad lookup is already nil so no need for or nil
		if (v[1] == current[1]) or (v[2] == current[2]) or (v[2] == 'z') or (v[2] == current[3]) then
			table.insert(playable, v)
		end
	end

	table.sort(playable, DEFAULT_SORT)
	return playable
end


function run()
	-- TODO need to handle initial wild
while true do
	local playable = can_play(turn)
	-- LUA DOESN'T HAVE A CONTINUE UGH make this 2 deep and use break?
	if #playable == 0 then
		-- draw until that changes. append it to playable
		-- if we get a wild we gotta run stats on the deck
		cards = draw() -- the last one has to be playable, the rest are hand-appended
		if cards == nil then
			-- frick, game over
			return
		end
		playable = {table.remove(cards)}
		-- move everything LEFT in cards to the end of the hand
		table.move(cards, 1, #cards, #players[turn].hand + 1, players[turn].hand)
	end
	
	local played = '??'

	if #playable == 1 then
		-- just do it. if it's wild, we need to check our numbers
		-- but a full analysis isn't really needed
		if playable[1][2] ~= 'z' then
			played = playable[1]
		else
			-- compute numbers, play a 3-code wild
			nil
		end
	else
		analyze(turn)
		-- UGH FIGURE IT OUT
	end
	
	play_card(played) -- cycle turns do whatever else is needed

end end


run()




if first[1] == 'S' then
	-- shift to 0-base, apply rotation, then shift back ;)
	turn = (((turn - 1) + order) % 4) + 1
elseif first[1] == 'R' then
	order = order * -1
end


